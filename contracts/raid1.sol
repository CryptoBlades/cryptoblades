pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./Promos.sol";
import "./util.sol";
import "./items/RaidTrinket.sol";
import "./items/KeyLootbox.sol";
import "./items/Junk.sol";

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

    // leaving link 0 empty intentionally
    uint256 public constant LINK_TRINKET = 1;
    uint256 public constant LINK_KEYBOX = 2;
    uint256 public constant LINK_JUNK = 3;

    uint256 public constant NUMBERPARAMETER_AUTO_DURATION = 1;

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    Promos public promos;

    struct Raider {
        address owner;
        uint256 charID;
        uint256 wepID;
        uint24 power;
        uint24 traitsCWS;//char trait, wep trait, wep statpattern, unused for now
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
    mapping(uint256 => mapping(address => uint256[])) public raidParticipantIndices;
    mapping(uint256 => mapping(address => bool)) public raidRewardClaimed;

    // link interface
    // the idea is to avoid littering the contract with variables for each type of reward
    mapping(uint256 => address) public links;
    // parameters to avoid littering the contract with more state vars
    mapping(uint256 => uint256) public numberParameters;

    event RaidStarted(uint256 indexed raidIndex,
        uint8 bossTrait,
        uint256 bossPower,
        uint256 endTime);
    event RaidJoined(uint256 raidIndex,
        address indexed user,
        uint256 indexed character,
        uint256 indexed weapon,
        uint256 skillPaid);
    event RaidCompleted(uint256 indexed raidIndex,
        uint8 outcome,
        uint256 bossRoll,
        uint256 playerRoll);
    
    // reward specific events for analytics
    event RewardClaimed(uint256 indexed raidIndex, address indexed user, uint256 characterCount);
    event RewardedXpBonus(uint256 indexed raidIndex, address indexed user, uint256 indexed charID, uint16 amount);
    event RewardedDustLB(uint256 indexed raidIndex, address indexed user, uint32 amount);
    event RewardedDust4B(uint256 indexed raidIndex, address indexed user, uint32 amount);
    event RewardedDust5B(uint256 indexed raidIndex, address indexed user, uint32 amount);
    event RewardedWeapon(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 indexed tokenID);
    event RewardedJunk(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 indexed tokenID);
    event RewardedTrinket(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 effect, uint256 indexed tokenID);
    event RewardedKeyBox(uint256 indexed raidIndex, address indexed user, uint256 indexed tokenID);

    function initialize(address gameContract) public initializer {
        
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        promos = Promos(game.promos());

        staminaCost = 200; // 5 mins each, or 16.666 hours
        durabilityCost = 20; // 50 mins each, or 16.666 hours
        joinCost = 0;// free (was going to be 10 USD)
        xpReward = 128 * 2; // 13 hour 20 min worth of fight xp, but we had double xp active on launch
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    function doRaidAuto() public restricted {
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))));
        uint256 power = ABDKMath64x64.divu(1,2).mulu(raidPlayerPower[raidIndex]);
        uint8 trait = uint8(seed % 4);
        uint256 duration = numberParameters[NUMBERPARAMETER_AUTO_DURATION];
        if(power == 0) {
            power = 50000;
        }
        if(duration == 0) {
            duration = 480; // 8 hrs
        }
        doRaidWithSeed(power, trait, duration, seed);
    }

    function doRaid(uint256 bossPower, uint8 bossTrait, uint256 durationMinutes) public restricted {
        doRaidWithSeed(bossPower, bossTrait, durationMinutes, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))));
    }

    function doRaidWithSeed(uint256 bossPower, uint8 bossTrait, uint256 durationMinutes, uint256 seed) public restricted {
        require(raidStatus[raidIndex] != STATUS_PAUSED, "Raid paused");

        if(raidStatus[raidIndex] == STATUS_STARTED
        && raidParticipants[raidIndex].length > 0) {
            completeRaidWithSeed(seed);
        }
        startRaid(bossPower, bossTrait, durationMinutes);
    }

    function startRaid(uint256 bossPower, uint8 bossTrait, uint256 durationMinutes) public restricted {
        raidStatus[raidIndex] = STATUS_STARTED;
        raidBossPower[raidIndex] = bossPower;
        raidBossTrait[raidIndex] = bossTrait;

        uint256 endTime = now + (durationMinutes * 1 minutes);
        raidEndTime[raidIndex] = endTime;

        emit RaidStarted(raidIndex, bossTrait, bossPower, endTime);
    }

    function joinRaid(uint256 characterID, uint256 weaponID) public {
        require(characters.canRaid(msg.sender, characterID));
        require(weapons.canRaid(msg.sender, weaponID));
        /*require(characters.ownerOf(characterID) == msg.sender);
        require(weapons.ownerOf(weaponID) == msg.sender);
        require(characters.getStaminaPoints(characterID) > 0, "You cannot join with 0 character stamina");
        require(weapons.getDurabilityPoints(weaponID) > 0, "You cannot join with 0 weapon durability");*/
        require(raidStatus[raidIndex] == STATUS_STARTED, "Cannot join raid right now!");
        require(raidEndTime[raidIndex] > now, "It is too late to join this raid!");

        uint256[] memory raiderIndices = raidParticipantIndices[raidIndex][msg.sender];
        for(uint i = 0; i < raiderIndices.length; i++) {
            require(raidParticipants[raidIndex][raiderIndices[i]].wepID != weaponID,
                "This weapon is already used in the raid");
            require(raidParticipants[raidIndex][raiderIndices[i]].charID != characterID,
                "This character is already participating");
        }

        (uint8 charTrait, uint24 basePowerLevel, /*uint64 timestamp*/) =
            unpackFightData(characters.getFightDataAndDrainStamina(
                                    characterID,
                                    uint8(staminaCost),
                                    true)
                                );

        (/*int128 weaponMultTarget*/,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            /*uint8 weaponTrait*/) = weapons.getFightDataAndDrainDurability(weaponID, charTrait, uint8(durabilityCost), true);
        
        uint24 power = getPlayerFinalPower(
            getPlayerPower(basePowerLevel, weaponMultFight, weaponBonusPower),
            charTrait,
            raidBossTrait[raidIndex]
        );
        raidPlayerPower[raidIndex] += power;

        //uint8 wepStatPattern = weapons.getStatPattern(weaponID);
        raidParticipantIndices[raidIndex][msg.sender].push(raidParticipants[raidIndex].length);
        raidParticipants[raidIndex].push(Raider(
            msg.sender,
            characterID,
            weaponID,
            power,
            0//uint24(charTrait) | (uint24(weaponTrait) << 8) | ((uint24(wepStatPattern)) << 16)//traitCWS
        ));

        uint256 joinCostPaid = 0;
        if(joinCost > 0) {
            joinCostPaid = game.usdToSkill(joinCost);
            game.payContractTokenOnly(msg.sender, joinCostPaid);
        }
        emit RaidJoined(raidIndex,
            msg.sender,
            characterID,
            weaponID,
            joinCostPaid);
    }

    function setRaidStatus(uint256 index, uint8 status) public restricted {
        // only use if absolutely necessary
        raidStatus[index] = status;
    }

    function completeRaid() public restricted {
        completeRaidWithSeed(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))));
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

        if(outcome == STATUS_WON) {
            // since we pay out exactly one trinket per raid, we might as well do it here
            Raider memory trinketWinner = raidParticipants[raidIndex][seed % raidParticipants[raidIndex].length];
            uint8 trinketStars = getTrinketStarsFromSeed(seed);
            uint256 trinketEffect = (seed / 100) % 5;
            uint tokenID =
                RaidTrinket(links[LINK_TRINKET]).mint(
                    trinketWinner.owner, trinketStars, trinketEffect
                );
            emit RewardedTrinket(raidIndex, trinketWinner.owner, trinketStars, trinketEffect, tokenID);
        }

        emit RaidCompleted(raidIndex, outcome, bossPower, roll);
        raidIndex++;
    }

    function getTrinketStarsFromSeed(uint256 seed) private pure returns(uint8 stars) {
        uint256 roll = seed % 100;
        if(roll < 1) {
            return 4; // 5* at 1%
        }
        else if(roll < 6) { // 4* at 5%
            return 3;
        }
        else if(roll < 21) { // 3* at 15%
            return 2;
        }
        else if(roll < 56) { // 2* at 35%
            return 1;
        }
        else {
            return 0; // 1* at 44%
        }
    }

    function unpackFightData(uint96 playerData)
        public pure returns (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) {

        charTrait = uint8(playerData & 0xFF);
        basePowerLevel = uint24((playerData >> 8) & 0xFFFFFF);
        timestamp = uint64((playerData >> 32) & 0xFFFFFFFFFFFFFFFF);
    }

    function getPlayerPower(
        uint24 basePower,
        int128 weaponMultiplier,
        uint24 bonusPower
    ) public pure returns(uint24) {
        return uint24(weaponMultiplier.mulu(basePower) + bonusPower);
    }

    function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        return (((attacker + 1) % 4) == defender); // Thanks to Tourist
    }

    function getPlayerFinalPower(uint24 playerPower, uint8 charTrait, uint8 bossTrait) public pure returns(uint24) {
        if(isTraitEffectiveAgainst(charTrait, bossTrait))
            return uint24(ABDKMath64x64.divu(1075,1000).mulu(uint256(playerPower)));
        return playerPower;
    }

    function claimReward(uint256 claimRaidIndex) public {
        // NOTE: this function is stack limited
        //claimRaidIndex can act as a version integer if future rewards change
        bool victory = raidStatus[claimRaidIndex] == STATUS_WON;
        require(victory || raidStatus[claimRaidIndex] == STATUS_LOST, "Raid not over");
        require(raidRewardClaimed[claimRaidIndex][msg.sender] == false, "Already claimed");

        uint256[] memory raiderIndices = raidParticipantIndices[claimRaidIndex][msg.sender];
        require(raiderIndices.length > 0, "None of your characters participated");

        uint256 earlyBonusCutoff = raidParticipants[claimRaidIndex].length/2+1; // first half of players
        // we grab raider info (power) and give out xp and raid stats
        for(uint i = 0; i < raiderIndices.length; i++) {
            uint256 raiderIndex = raiderIndices[i];
            Raider memory raider = raidParticipants[claimRaidIndex][raiderIndex];
            int128 earlyMultiplier = ABDKMath64x64.fromUInt(1).add(
                raiderIndex < earlyBonusCutoff ?
                    ABDKMath64x64.divu(1,10).mul( // early bonus, 10%
                        (earlyBonusCutoff-raiderIndex).divu(earlyBonusCutoff)
                    )
                    : ABDKMath64x64.fromUInt(0)
            );
            if(victory) {
                distributeRewards(
                    claimRaidIndex,
                    raiderIndex,
                    ABDKMath64x64.divu(earlyMultiplier.mulu(raider.power),
                        raidPlayerPower[claimRaidIndex]/raidParticipants[claimRaidIndex].length)
                );
            }
            characters.processRaidParticipation(raider.charID, victory, uint16(earlyMultiplier.mulu(xpReward)));
        }

        raidRewardClaimed[claimRaidIndex][msg.sender] = true;
        emit RewardClaimed(claimRaidIndex, msg.sender, raiderIndices.length);
    }

    function distributeRewards(
        uint256 claimRaidIndex,
        uint256 raiderIndex,
        int128 comparedToAverage
    ) private {
        // at most 2 types of rewards
        // common: Lb dust, 1-3 star junk, 3 star wep
        // rare: 4-5b dust, 4-5 star wep, 4-5 star junk, keybox
        // chances are a bit generous compared to weapon mints because stamina cost equals lost skill
        // That being said these rates stink if the oracle is 3x lower than real value.
        uint256 seed = uint256(keccak256(abi.encodePacked(raidSeed[claimRaidIndex], raiderIndex, uint256(msg.sender))));

        uint256 commonRoll = RandomUtil.randomSeededMinMax(1, 15 + comparedToAverage.mulu(85), seed);
        if(commonRoll > 20) { // Expected: ~75% (at least 25% at bottom, 90+% past 65% power)
            uint mod = seed % 10;
            if(mod < 2) { // 1 star junk, 2 out of 10 (20%)
                distributeJunk(msg.sender, claimRaidIndex, 0);
            }
            else if(mod < 4) { // 2 star junk, 2 out of 10 (20%)
                distributeJunk(msg.sender, claimRaidIndex, 1);
            }
            else if(mod < 6) { // 2 star weapon, 2 out of 10 (20%)
                distributeWeapon(msg.sender, claimRaidIndex, seed, 1);
            }
            else if(mod == 6) { // 3 star junk, 1 out of 10 (10%)
                distributeJunk(msg.sender, claimRaidIndex, 2);
            }
            else if(mod == 7) { // 1x LB Dust, 1 out of 10 (10%)
                distributeLBDust(msg.sender, claimRaidIndex, 1);
            }
            else if(mod == 8) { // 2x LB Dust, 1 out of 10 (10%)
                distributeLBDust(msg.sender, claimRaidIndex, 2);
            }
            else { // 3 star weapon, 1 out of 10 (10%)
                distributeWeapon(msg.sender, claimRaidIndex, seed, 2);
            }
        }

        uint256 rareRoll = RandomUtil.randomSeededMinMax(1, 950 + comparedToAverage.mulu(50), seed + 1);
        if(rareRoll > 950) { // Expected: ~5% (0.72% at bottom, 15% at top, 8.43% middle)
            uint mod = (seed / 10) % 20;
            if(mod < 8) { // key box, 8 out of 20 (40%)
                distributeKeyBox(msg.sender, claimRaidIndex);
            }
            else if(mod == 8) { // 5 star sword, 1 out of 20 (5%)
                distributeWeapon(msg.sender, claimRaidIndex, seed, 4);
            }
            else if(mod == 9) { // 5 star junk, 1 out of 20 (5%)
                distributeJunk(msg.sender, claimRaidIndex, 4);
            }
            else if(mod < 14) { // 4 star sword, 4 out of 20 (20%)
                distributeWeapon(msg.sender, claimRaidIndex, seed, 3);
            }
            else if(mod == 14) { // 1x 4B Dust, 1 out of 20 (5%)
                distribute4BDust(msg.sender, claimRaidIndex, 1);
            }
            else if(mod == 15) { // 1x 5B Dust, 1 out of 20 (5%)
                distribute5BDust(msg.sender, claimRaidIndex, 1);
            }
            else { // 4 star junk, 4 out of 20 (20%)
                distributeJunk(msg.sender, claimRaidIndex, 3);
            }
        }

        uint256 bonusXpRoll = RandomUtil.randomSeededMinMax(1, 2000, seed + 2); // 0.05% per point
        if(bonusXpRoll <= 100) { // 5% for any bonus xp result
            if(bonusXpRoll > 50) { // 2.5% for +25% xp
                distributeBonusXp(msg.sender, claimRaidIndex, raiderIndex, uint16(ABDKMath64x64.divu(25,100).mulu(xpReward)));
            }
            else if(bonusXpRoll > 20) { // 1.5% for +150% xp
                distributeBonusXp(msg.sender, claimRaidIndex, raiderIndex, uint16(ABDKMath64x64.divu(150,100).mulu(xpReward)));
            }
            else if(bonusXpRoll > 10) { // 0.5% for +275% xp
                distributeBonusXp(msg.sender, claimRaidIndex, raiderIndex, uint16(ABDKMath64x64.divu(275,100).mulu(xpReward)));
            }
            else if(bonusXpRoll > 4) { // 0.3% for +525% xp
                distributeBonusXp(msg.sender, claimRaidIndex, raiderIndex, uint16(ABDKMath64x64.divu(525,100).mulu(xpReward)));
            }
            else if(bonusXpRoll > 1) { // 0.15% for +1150% xp
                distributeBonusXp(msg.sender, claimRaidIndex, raiderIndex, uint16(ABDKMath64x64.divu(1150,100).mulu(xpReward)));
            }
            else { // 0.05% for +2400% xp
                distributeBonusXp(msg.sender, claimRaidIndex, raiderIndex, uint16(ABDKMath64x64.divu(2400,100).mulu(xpReward)));
            }
        }
    }

    function distributeBonusXp(address claimant, uint256 claimRaidIndex, uint256 raiderIndex, uint16 amount) private {
        uint256 charID = raidParticipants[claimRaidIndex][raiderIndex].charID;
        characters.gainXp(charID, amount);
        emit RewardedXpBonus(claimRaidIndex, claimant, charID, amount);
    }

    function distributeKeyBox(address claimant, uint256 claimRaidIndex) private {
        uint tokenID = KeyLootbox(links[LINK_KEYBOX]).mint(claimant);
        emit RewardedKeyBox(claimRaidIndex, claimant, tokenID);
    }

    function distributeJunk(address claimant, uint256 claimRaidIndex, uint8 stars) private {
        uint tokenID = Junk(links[LINK_JUNK]).mint(claimant, stars);
        emit RewardedJunk(claimRaidIndex, claimant, stars, tokenID);
    }

    function distributeWeapon(address claimant, uint256 claimRaidIndex, uint256 seed, uint8 stars) private {
        uint tokenID = weapons.mintWeaponWithStars(claimant, stars, seed / 100);
        emit RewardedWeapon(claimRaidIndex, claimant, stars, tokenID);
    }

    function distributeLBDust(address claimant, uint256 claimRaidIndex, uint32 amount) private {
        weapons.incrementDustSupplies(claimant, amount, 0, 0);
        emit RewardedDustLB(claimRaidIndex, claimant, amount);
    }

    function distribute4BDust(address claimant, uint256 claimRaidIndex, uint32 amount) private {
        weapons.incrementDustSupplies(claimant, 0, amount, 0);
        emit RewardedDust4B(claimRaidIndex, claimant, amount);
    }

    function distribute5BDust(address claimant, uint256 claimRaidIndex, uint32 amount) private {
        weapons.incrementDustSupplies(claimant, 0, 0, amount);
        emit RewardedDust5B(claimRaidIndex, claimant, amount);
    }

    function registerLink(address addr, uint256 index) public restricted {
        links[index] = addr;
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

    function setNumberParameter(uint256 paramIndex, uint256 value) public restricted {
        numberParameters[paramIndex] = value;
    }

    function getNumberParameter(uint256 paramIndex) public view returns(uint256) {
        return numberParameters[paramIndex];
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
                result[currentIndex++] = i;
            }
        }
        return result;
    }

    function isEligibleForReward(uint256 index) public view returns(bool) {
        return raidParticipantIndices[index][msg.sender].length > 0
            && raidRewardClaimed[index][msg.sender] == false
            && (raidStatus[index] == STATUS_WON || raidStatus[index] == STATUS_LOST);
    }

    function getParticipatingCharacters() public view returns(uint256[] memory) {
        uint256[] memory indices = raidParticipantIndices[raidIndex][msg.sender];
        uint256[] memory chars = new uint256[](indices.length);
        for(uint i = 0; i < indices.length; i++) {
            chars[i] = raidParticipants[raidIndex][indices[i]].charID;
        }
        return chars;
    }
    
    function getParticipatingWeapons() public view returns(uint256[] memory) {
        uint256[] memory indices = raidParticipantIndices[raidIndex][msg.sender];
        uint256[] memory weps = new uint256[](indices.length);
        for(uint i = 0; i < indices.length; i++) {
            weps[i] = raidParticipants[raidIndex][indices[i]].wepID;
        }
        return weps;
    }

    function getAccountsRaiderIndexes(uint256 index) public view returns(uint256[] memory){
        return raidParticipantIndices[index][msg.sender];
    }

    function getAccountsPower(uint256 index) public view returns(uint256) {
        uint256 totalAccountPower = 0;
        uint256[] memory raiderIndexes = getAccountsRaiderIndexes(index);
        for(uint256 i = 0; i < raiderIndexes.length; i++) {
            totalAccountPower += raidParticipants[index][raiderIndexes[i]].power;
        }
        return totalAccountPower;
    }
    
    function canJoinRaid(uint256 characterID, uint256 weaponID) public view returns(bool) {
        return isRaidStarted()
            && haveEnoughEnergy(characterID, weaponID)
            && !isCharacterRaiding(characterID)
            && !isWeaponRaiding(weaponID);
    }

    function haveEnoughEnergy(uint256 characterID, uint256 weaponID) public view returns(bool) {
        return characters.getStaminaPoints(characterID) > 0 && weapons.getDurabilityPoints(weaponID) > 0;
    }

    function isRaidStarted() public view returns(bool) {
        return raidStatus[raidIndex] == STATUS_STARTED && raidEndTime[raidIndex] > now;
    }

    function isWeaponRaiding(uint256 weaponID) public view returns(bool) {
        uint256[] memory raiderIndices = raidParticipantIndices[raidIndex][msg.sender];
        for(uint i = 0; i < raiderIndices.length; i++) {
            if(raidParticipants[raidIndex][raiderIndices[i]].wepID == weaponID) {
                return true;
            }
        }

        return false;
    }

    function isCharacterRaiding(uint256 characterID) public view returns(bool) {
        uint256[] memory raiderIndices = raidParticipantIndices[raidIndex][msg.sender];
        for(uint i = 0; i < raiderIndices.length; i++) {
            if(raidParticipants[raidIndex][raiderIndices[i]].charID == characterID) {
                return true;
            }
        }

        return false;
    }

    function getLinkAddress(uint256 linkIndex) public view returns (address) {
        return links[linkIndex];
    }

    function getRaidData() public view returns(
        uint256 index, uint256 endTime, uint256 raiderCount, uint256 playerPower, uint256 bossPower,
        uint8 trait, uint8 status, uint256 joinSkill, uint64 stamina, uint64 durability, uint64 xp, uint256 accountPower
    ) {
        index = raidIndex;
        endTime = raidEndTime[raidIndex];
        raiderCount = getRaidParticipantCount(raidIndex);
        playerPower = getRaidPlayerPower(raidIndex);
        bossPower = getRaidBossPower(raidIndex);
        trait = getRaidBossTrait(raidIndex);
        status = getRaidStatus(raidIndex);
        joinSkill = getJoinCostInSkill();
        stamina = staminaCost;
        durability = durabilityCost;
        xp = xpReward;
        accountPower = getAccountsPower(raidIndex);
    }
}