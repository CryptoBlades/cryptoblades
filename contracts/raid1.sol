pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./util.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IERC20MintAccess.sol";
import "./interfaces/IERC721MintAccessSeeded.sol";
import "./interfaces/IERC721MintAccessSeededStars.sol";

contract Raid1 is Initializable, AccessControlUpgradeable {

    /*
        Actual raids reimplementation
        Figured the old contract may have a lot of redundant variables and it's already deployed
        Maybe the raid interface isn't the way to go
        Either way it's probably fine to lay out the new one in a single file and compare
        The idea is to store all participants and raid details using an indexed mapping system
        And players get to claim their rewards as a derivative of a raid completion seed that
            a safe verifiable random source will provide (ideally)
        It may be better to convert the mappings using raidIndex into a struct
        Need to test gas impact or if stack limits are any different
    */

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    uint8 public constant STATUS_UNSTARTED = 0;
    uint8 public constant STATUS_STARTED = 1;
    uint8 public constant STATUS_WON = 2;
    uint8 public constant STATUS_LOST = 3;
    uint8 public constant STATUS_PAUSED = 4; // in case of emergency

    /*uint256 public constant REWARD_ERC20_DUST_LB = 0;
    uint256 public constant REWARD_ERC20_DUST_4B = 1;
    uint256 public constant REWARD_ERC20_DUST_5B = 2;*/
    uint256 public constant REWARD_ERC721SEEDED_KEYBOX = 0;
    uint256 public constant REWARD_ERC721SEEDEDSTARS_TRINKET = 0;
    uint256 public constant REWARD_ERC721SEEDEDSTARS_WEAPON = 1;
    uint256 public constant REWARD_ERC721SEEDEDSTARS_JUNK = 2;

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;

    struct Raider {
        uint256 owner;
        uint256 charID;
        uint256 wepID;
        uint24 power;
        uint24 traitsCWS;//char trait, wep trait, wep statpattern
    }

    uint64 public staminaCost;
    uint64 public durabilityCost;
    int128 public joinCost;
    uint16 public xpReward;

    uint256 public raidIndex;
    // all (first) keys are raidIndex
    mapping(uint256 => uint8) public raidStatus;
    mapping(uint256 => uint256) public raidEndTime;
    mapping(uint256 => uint256) public raidSeed;
    mapping(uint256 => uint8) public raidBossTrait;
    mapping(uint256 => uint256) public raidBossPower;
    mapping(uint256 => uint256) public raidPlayerPower;
    mapping(uint256 => Raider[]) public raidParticipants;
    mapping(uint256 => mapping(uint256/*address*/ => uint256[])) public raidParticipantIndices;
    mapping(uint256 => mapping(uint256 => bool)) public raidRewardClaimed;

    // reward interface, keys are reward indices that are unique per-type
    // the idea is to avoid littering the contract with variables for each type of reward
    mapping(uint256 => IERC20MintAccess) public rewardsERC20;
    mapping(uint256 => IERC721MintAccessSeeded) public rewardsERC721Seeded;
    mapping(uint256 => IERC721MintAccessSeededStars) public rewardsERC721SeededStars;

    event RaidStarted(uint256 indexed raidIndex, uint8 bossTrait, uint256 bossPower, uint256 endTime);
    event RaidJoined(uint256 raidIndex,
        address indexed user,
        uint256 indexed character,
        uint256 indexed weapon,
        uint256 skillPaid);
    event RaidCompleted(uint256 indexed raidIndex, uint8 outcome, uint256 bossRoll, uint256 playerRoll);
    
    // reward specific events for analytics
    event RewardClaimed(uint256 indexed raidIndex, address indexed user, uint256 characterCount);
    /*event RewardedDustLB(uint256 indexed raidIndex, address indexed user, uint256 amount);
    event RewardedDust4B(uint256 indexed raidIndex, address indexed user, uint256 amount);
    event RewardedDust5B(uint256 indexed raidIndex, address indexed user, uint256 amount);*/
    event RewardedWeapon(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 indexed tokenID);
    event RewardedJunk(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 indexed tokenID);
    event RewardedTrinket(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 indexed tokenID);
    event RewardedKeyBox(uint256 indexed raidIndex, address indexed user, uint256 indexed tokenID);

    function initialize(address gameContract) public initializer {
        
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());

        staminaCost = 192; // 5 mins each, or 16 hours
        durabilityCost = 20; // 48 mins each, or 16 hours
        joinCost = ABDKMath64x64.fromUInt(10);// 10 usd
        xpReward = 128; // 13 hour 20 min worth of fight xp
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function startRaid(uint256 bossPower, uint8 bossTrait, uint256 durationHours) public restricted {
        raidStatus[raidIndex] = STATUS_STARTED;
        raidBossPower[raidIndex] = bossPower;
        raidBossTrait[raidIndex] = bossTrait;

        uint256 endTime = now + (durationHours * 1 hours);
        raidEndTime[raidIndex] = endTime;

        emit RaidStarted(raidIndex, bossTrait, bossPower, endTime);
    }

    function joinRaid(uint256 characterID, uint256 weaponID) public {
        require(characters.ownerOf(characterID) == msg.sender);
        require(weapons.ownerOf(weaponID) == msg.sender);
        require(characters.getStaminaPoints(characterID) > 0, "You cannot join with 0 character stamina");
        require(weapons.getDurabilityPoints(weaponID) > 0, "You cannot join with 0 weapon durability");
        require(raidStatus[raidIndex] == STATUS_STARTED, "Cannot join raid right now!");
        require(raidEndTime[raidIndex] > now, "It is too late to join this raid!");

        (uint8 charTrait, uint24 basePowerLevel, /*uint64 timestamp*/) =
            game.unpackFightData(characters.getFightDataAndDrainStamina(
                                    characterID,
                                    uint8(staminaCost),
                                    true)
                                );

        (/*int128 weaponMultTarget*/,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightData(weaponID, charTrait);
        weapons.drainDurability(weaponID, uint8(durabilityCost), true);
        
        uint24 power = getPlayerFinalPower(
            game.getPlayerPower(basePowerLevel, weaponMultFight, weaponBonusPower),
            charTrait,
            raidBossTrait[raidIndex]
        );
        raidPlayerPower[raidIndex] += power;

        uint8 wepStatPattern = weapons.getStatPattern(weaponID);
        raidParticipantIndices[raidIndex][uint256(msg.sender)].push(raidParticipants[raidIndex].length);
        raidParticipants[raidIndex].push(Raider(
            uint256(msg.sender),
            characterID,
            weaponID,
            power,
            uint24(charTrait) | (uint24(weaponTrait) << 8) | ((uint24(wepStatPattern)) << 16)//traitCWS
        ));

        emit RaidJoined(raidIndex,
            msg.sender,
            characterID,
            weaponID,
            game.usdToSkill(joinCost));
        
        // maybe "restrict" this pay method and do the join from game?
        // it woul help simplify gas usage analytics and skill approvals
        // we may need the "requestPayFromPlayer" modifier
        // game contract would need a raid contract link
        game.payContract(msg.sender, joinCost);
    }

    function setRaidStatus(uint256 index, uint8 status) public restricted {
        // only use if absolutely necessary
        raidStatus[index] = status;
    }

    function completeRaid() public restricted {
        completeRaidWithSeed(game.randoms().getRandomSeed(msg.sender));
    }

    function completeRaidWithSeed(uint256 seed) internal {

        raidSeed[raidIndex] = seed;
        raidEndTime[raidIndex] = now;

        uint256 bossPower = raidBossPower[raidIndex];
        // we could also not include bossPower in the roll to have slightly higher chances of failure
        // with bosspower added to roll ceiling the likelyhood of a win is: playerPower / bossPower
        uint256 roll = RandomUtil.randomSeededMinMax(0,raidPlayerPower[raidIndex]+bossPower, seed);
        uint8 outcome = roll > bossPower ? STATUS_WON : STATUS_LOST;
        raidStatus[raidIndex] = outcome;

        // since we pay out exactly one trinket per raid, we might as well do it here
        Raider memory trinketWinner = raidParticipants[raidIndex][seed % raidParticipants[raidIndex].length];
        uint8 trinketStars = uint8(seed % 5);
        uint tokenID =
            rewardsERC721SeededStars[REWARD_ERC721SEEDEDSTARS_TRINKET].mintAccessSeededStars(
                address(trinketWinner.owner), raidIndex, seed, trinketStars
            );
        emit RewardedTrinket(raidIndex, address(trinketWinner.owner), trinketStars, tokenID);

        emit RaidCompleted(raidIndex, outcome, bossPower, roll);
        raidIndex++;
    }

    function getPlayerFinalPower(uint24 playerPower, uint8 charTrait, uint8 bossTrait) public view returns(uint24) {
        if(game.isTraitEffectiveAgainst(charTrait, bossTrait))
            return uint24(ABDKMath64x64.divu(1075,1000).mulu(uint256(playerPower)));
        return playerPower;
    }

    function claimReward(uint256 claimRaidIndex) public {
        // NOTE: this function is stack limited
        //claimRaidIndex can act as a version integer if future rewards change
        bool victory = raidStatus[claimRaidIndex] == STATUS_WON;
        require(victory || raidStatus[claimRaidIndex] == STATUS_LOST, "Raid not over");
        require(raidRewardClaimed[claimRaidIndex][uint256(msg.sender)] == false, "Already claimed");

        uint256[] memory raiderIndices = raidParticipantIndices[claimRaidIndex][uint256(msg.sender)];
        require(raiderIndices.length > 0, "None of your characters participated");

        int128 earlyBonus = ABDKMath64x64.divu(1,10); // up to 10%
        uint256 earlyBonusCutoff = raidParticipants[claimRaidIndex].length/2; // first half of players
        // we grab raider info (power) and give out xp and raid stats
        for(uint i = 0; i < raiderIndices.length; i++) {
            uint256 raiderIndex = raiderIndices[i];
            Raider memory raider = raidParticipants[claimRaidIndex][raiderIndex];
            int128 earlyMultiplier = ABDKMath64x64.fromUInt(1).add(
                earlyBonus.mul(
                    (earlyBonusCutoff-raiderIndex).divu(earlyBonusCutoff)
                )
            );
            if(victory) {
                distributeRewards(
                    claimRaidIndex,
                    ABDKMath64x64.divu(earlyMultiplier.mulu(raider.power),
                        raidPlayerPower[claimRaidIndex]/raidParticipants[claimRaidIndex].length)
                );
            }
            characters.processRaidParticipation(raider.charID, victory, uint16(earlyMultiplier.mulu(xpReward)));
        }

        raidRewardClaimed[claimRaidIndex][uint256(msg.sender)] = true;
        emit RewardClaimed(claimRaidIndex, msg.sender, raiderIndices.length);
    }

    function distributeRewards(
        uint256 claimRaidIndex,
        int128 comparedToAverage
    ) private {
        // at most 2 types of rewards
        // dust is not implemented yet so we can expand with that later
        // common: Lb dust, 1-3 star junk, 3 star wep
        // rare: 4-5b dust, 4-5 star wep, 4-5 star junk, keybox
        // chances are a bit generous compared to weapon mints because stamina cost equals lost skill
        // That being said these rates stink if the oracle is 3x lower than real value.
        uint256 seed = RandomUtil.combineSeeds(raidSeed[claimRaidIndex], uint256(msg.sender));

        uint256 commonRoll = RandomUtil.randomSeededMinMax(1, comparedToAverage.mulu(100), seed);
        if(commonRoll > 10) { // 90% base chance
            uint mod = seed % 6;
            if(mod == 0) { // 1 star junk, 1 out of 5 (20%)
                distributeJunk(msg.sender, claimRaidIndex, seed, 0);
            }
            else if(mod == 1) { // 2 star junk, 1 out of 5 (20%)
                distributeJunk(msg.sender, claimRaidIndex, seed, 1);
            }
            else if(mod < 4) { // 3 star junk, 2 out of 4 (40%)
                distributeJunk(msg.sender, claimRaidIndex, seed, 2);
            }
            else { // 3 star weapon, 2 out of 4 (40%)
                distributeWeapon(msg.sender, claimRaidIndex, seed, 2);
            }
        }

        uint256 rareRoll = RandomUtil.randomSeededMinMax(1, 950 + comparedToAverage.mulu(50), seed + 1);
        if(rareRoll > 950) { // 5% base chance
            uint mod = (seed / 10) % 14;
            if(mod == 0) { // key box, 1 out of 13 (7.69%)
                distributeKeyBox(msg.sender, claimRaidIndex, seed);
            }
            else if(mod == 1) { // 5 star sword, 1 out of 13 (7.69%)
                distributeWeapon(msg.sender, claimRaidIndex, seed, 4);
            }
            else if(mod == 2) { // 5 star junk, 1 out of 13 (7.69%)
                distributeJunk(msg.sender, claimRaidIndex, seed, 4);
            }
            else if(mod < 8) { // 4 star sword, 5 out of 13 (38.4%)
                distributeWeapon(msg.sender, claimRaidIndex, seed, 3);
            }
            else { // 4 star junk, 5 out of 13 (38.4%)
                distributeJunk(msg.sender, claimRaidIndex, seed, 3);
            }
        }
    }

    function distributeKeyBox(address claimant, uint256 claimRaidIndex, uint256 seed) public restricted {
        uint tokenID = rewardsERC721Seeded[REWARD_ERC721SEEDEDSTARS_WEAPON].mintAccessSeeded(
                claimant, claimRaidIndex, seed
            );
        emit RewardedKeyBox(claimRaidIndex, claimant, tokenID);
    }

    function distributeJunk(address claimant, uint256 claimRaidIndex, uint256 seed, uint8 stars) public restricted {
        uint tokenID = rewardsERC721SeededStars[REWARD_ERC721SEEDEDSTARS_JUNK].mintAccessSeededStars(
                claimant, claimRaidIndex, seed, stars
            );
        emit RewardedJunk(claimRaidIndex, claimant, stars, tokenID);
    }

    function distributeWeapon(address claimant, uint256 claimRaidIndex, uint256 seed, uint8 stars) public restricted {
        uint tokenID = rewardsERC721SeededStars[REWARD_ERC721SEEDEDSTARS_WEAPON].mintAccessSeededStars(
                claimant, claimRaidIndex, seed, stars
            );
        emit RewardedWeapon(claimRaidIndex, claimant, stars, tokenID);
    }

    function registerERC20RewardAddress(address addr, uint256 index) public restricted {
        rewardsERC20[index] = IERC20MintAccess(addr);
    }

    function registerERC721RewardSeededAddress(address addr, uint256 index) public restricted {
        rewardsERC721Seeded[index] = IERC721MintAccessSeeded(addr);
    }

    function registerERC721RewardSeededStarsAddress(address addr, uint256 index) public restricted {
        rewardsERC721SeededStars[index] = IERC721MintAccessSeededStars(addr);
    }

    function setStaminaPointCost(uint8 points) public restricted {
        staminaCost = points;
    }

    function setDurabilityPointCost(uint8 points) public restricted {
        durabilityCost = points;
    }

    function setJoinCostInCents(uint256 cents) public restricted {
        joinCost = ABDKMath64x64.divu(cents, 100);
    }

    function getJoinCostInSkill() public view returns(uint256) {
        return game.usdToSkill(joinCost);
    }

    function setXpReward(uint16 xp) public restricted {
        xpReward = xp;
    }

    function getRaidStatus(uint256 index) public view returns(uint8) {
        return raidStatus[index];
    }

    function getRaidEndTime(uint256 index) public view returns(uint256) {
        return raidEndTime[index];
    }

    function getRaidBossTrait(uint256 index) public view returns(uint8) {
        return raidBossTrait[index];
    }

    function getRaidBossPower(uint256 index) public view returns(uint256) {
        return raidBossPower[index];
    }

    function getRaidPlayerPower(uint256 index) public view returns(uint256) {
        return raidPlayerPower[index];
    }

    function getRaidParticipantCount(uint256 index) public view returns(uint256) {
        return raidParticipants[index].length;
    }

    function getEligibleRewardIndexes(uint256 startIndex, uint256 endIndex) public view returns(uint256[] memory) {
        uint indexCount = 0;
        for(uint i = startIndex; i <= endIndex; i++) {
            if(isEligibleForReward(i)) {
                indexCount++;
            }
        }
        uint256[] memory result = new uint256[](indexCount);
        uint currentIndex = 0;
        for(uint i = startIndex; i <= endIndex; i++) {
            if(isEligibleForReward(i)) {
                result[currentIndex] = i;
            }
        }
    }

    function isEligibleForReward(uint256 index) public view returns(bool) {
        return raidParticipantIndices[index][uint256(msg.sender)].length > 0
            && raidRewardClaimed[index][uint256(msg.sender)] == false;
    }

    function getParticipatingCharacters() public view returns(uint256[] memory) {
        uint256[] memory indices = raidParticipantIndices[raidIndex][uint256(msg.sender)];
        uint256[] memory chars = new uint256[](indices.length);
        for(uint i = 0; i < indices.length; i++) {
            chars[i] = raidParticipants[raidIndex][i].charID;
        }
        return chars;
    }
    
    function getParticipatingWeapons() public view returns(uint256[] memory) {
        uint256[] memory indices = raidParticipantIndices[raidIndex][uint256(msg.sender)];
        uint256[] memory weps = new uint256[](indices.length);
        for(uint i = 0; i < indices.length; i++) {
            weps[i] = raidParticipants[raidIndex][i].wepID;
        }
        return weps;
    }
}