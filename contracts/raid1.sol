pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "./raid.sol";

contract Raid1 is Initializable, MultiAccessUpgradeable {

    /*
        WIP raids reimplementation
        Figured the old contract may have a lot of redundant variables and it's already deployed
        Maybe the raid interface isn't the way to go
        Either way it's probably fine to lay out the new one in a single file and compare
        The idea is to store all participants and raid details using an indexed mapping system
        And players get to claim their rewards as a derivative of a raid completion seed that
            a safe verifiable random source will provide (ideally)
        
    */

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

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

    uint64 public staminaDrain;
    int128 public joinCost;

    uint256 public raidIndex;
    // all keys are raidIndex
    mapping(uint256 => bool) public raidCompleted; // may be unnecessary if you do completionseed != 0
    mapping(uint256 => uint256) public raidEndTime; // check == 0 to see if it started yet
    mapping(uint256 => uint256) public raidCompletionSeeds;
    mapping(uint256 => uint8) public raidBossTrait;
    mapping(uint256 => uint256) public raidBossPower;
    mapping(uint256 => uint256) public raidPlayerPower;
    mapping(uint256 => Raider[]) public raidParticipants;
    mapping(uint256 => mapping(uint256/*address*/ => uint256[])) public raidParticipantIndices;
    mapping(uint256 => mapping(uint256 => bool)) public raidRewardClaimed;

    event RaidStarted(uint256 indexed raidIndex, uint8 bossTrait, uint256 bossPower, uint256 endTime);
    event RaidJoined(uint256 indexed raidIndex,
        address indexed user,
        uint256 indexed character,
        uint256 indexed weapon,
        uint256 skillPaid);
    event RaidCompleted(uint256 indexed raidIndex, bool victory, uint256 bossPower, uint256 playerPower);
    
    // reward specific events for analytics
    event RewardClaimed(uint256 indexed raidIndex, address indexed user);
    event RewardedDustLB(uint256 indexed raidIndex, address indexed user, uint256 amount);
    event RewardedDust4B(uint256 indexed raidIndex, address indexed user, uint256 amount);
    event RewardedDust5B(uint256 indexed raidIndex, address indexed user, uint256 amount);
    event RewardedWeapon(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 indexed tokenID);
    event RewardedJunk(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 indexed tokenID);
    event RewardedTrinket(uint256 indexed raidIndex, address indexed user, uint8 stars, uint256 indexed tokenID);
    event RewardedKeyBox(uint256 indexed raidIndex, address indexed user, uint256 indexed tokenID);

    function initialize(address gameContract) public initializer {
        
        MultiAccessUpgradeable.initialize();

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());

        staminaDrain = 57600; // 16 hours
        joinCost = ABDKMath64x64.fromUInt(10);// 10 usd
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function joinRaid(uint256 characterID, uint256 weaponID) public {
        require(characters.ownerOf(characterID) == msg.sender);
        require(weapons.ownerOf(weaponID) == msg.sender);
        require(characters.getStaminaPoints(characterID) > 0, "You cannot join with 0 character stamina");
        require(weapons.getDurabilityPoints(weaponID) > 0, "You cannot join with 0 weapon durability");

        (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) =
            game.unpackFightData(characters.getFightDataAndDrainStamina(characterID, staminaDrain, true));

        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightData(wep, charTrait);
        
        weapons.drainDurability(weaponID, staminaDrain, true);

        uint24 power = getPlayerFinalPower(
            game.getPlayerPower(basePowerLevel, weaponMultFight, weaponBonusPower),
            charTrait,
            raidBossTrait[raidIndex]
        );
        totalPower += power;
        uint8 wepStatPattern = weapons.getStatPattern(weaponID);

        raidParticipants[raidIndex].push(Raider(uint256(msg.sender), characterID, weaponID, power, traitCWS));

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

    function getPlayerFinalPower(uint24 playerPower, uint8 charTrait, uint8 bossTrait) returns(uint24) {
        if(game.isTraitEffectiveAgainst(charTrait, bossTrait))
            return uint24(ABDKMath64x64.divu(1075,1000).mulu(uint256(playerPower)));
        return playerPower;
    }

    function completeRaid(uint256 seed) public restricted {
        
        emit RaidCompleted();
    }

    function claimReward(uint256 raidIndex) public {
        //characters.processRaidParticipation(charID, victory, xp)
    }

    function getTotalPower() public view returns(uint256) {
        return totalPower;
    }

    function setStaminaDrainSeconds(uint64 secs) public restricted {
        staminaDrain = secs;
    }

    function getStaminaDrainSeconds() public view returns(uint64) {
        return staminaDrain;
    }

    function setJoinCostInCents(uint256 cents) public restricted {
        joinCost = ABDKMath64x64.divu(cents, 100);
    }
}