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

    bool public completed;
    uint256 public expectedFinishTime; // not a guarantee since we don't automate this (atm)

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;

    struct Raider {
        uint256 owner;
        uint256 charID;
        uint256 wepID;
        uint24 power;
    }

    uint64 public staminaDrain;
    uint8 bossTrait; // set manually for now

    uint256 totalPower;

    int128 joinCost;

    uint256 raidIndex;
    mapping(uint256 => bool) public raidCompleted;
    mapping(uint256 => uint256) public raidCompletionSeeds;
    mapping(uint256 => uint8) public raidBossTrait;
    mapping(uint256 => uint256) public raidBossPower;

    event RewardClaimed(address addr);

    function initialize(address gameContract) public initializer {
        
        MultiAccessUpgradeable.initialize();

        grantAccess(gameContract);
        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());

        staminaDrain = 16 * 60 * 60;
        joinCost = ABDKMath64x64.fromUInt(10);// 10 usd
    }

    function addRaider(uint256 characterID, uint256 weaponID) public override {
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

        uint24 power = game.getPlayerPower(basePowerLevel, weaponMultFight, weaponBonusPower);
        //game.getPlayerPowerRoll(playerFightPower,traitsCWE,seed);
        totalPower += power;
        raiders.push(Raider(uint256(msg.sender), characterID, weaponID, power));

        emit RaiderJoined(msg.sender, characterID, weaponID, power);
        
        // maybe "restrict" this pay method and do the join from game?
        // we may need the "requestPayFromPlayer" modifier
        game.payContract(msg.sender, joinCost);
    }

    function completeRaid(uint256 seed) public override restricted {
        require(completed == false, "Raid already completed, run reset first");
        completed = true;

        raidCompletionSeeds[currentRaidIndex++] = seed;

        // TODO rewards, on claim (including xp)
        /*for(uint i = 0; i < raiders.length; i++) {
            emit XpReward(address(raiders[i].owner), raiders[i].charID, 96);
            characters.gainXp(raiders[i].charID, 96);
        }*/
        /*for(uint i = 0; i < raiders.length; i++) {
            Raider memory r = raiders[i];

            int128 powerPercentage = uint256(r.power).divu(totalPower);
            uint256 payout = powerPercentage.mulu(bounty);
            game.payPlayerConverted(address(r.owner), payout);
            emit SkillWinner(address(r.owner), payout);
        }*/

        for(uint i = 0; i < weaponDrops.length; i++) {
            Raider memory r = raiders[RandomUtil.randomSeededMinMax(0, raiders.length-1, RandomUtil.combineSeeds(seed,i))];
            game.approveContractWeaponFor(weaponDrops[i], address(this));
            weapons.transferFrom(address(game), address(r.owner), weaponDrops[i]);
            emit WeaponWinner(address(r.owner), weaponDrops[i]);
        }

        emit RaidCompleted();
    }

    function reset() public override restricted {
        totalPower = 0;
        super.reset();
    }

    function setBossTrait(uint8 trait) public restricted {
        bossTrait = trait;
    }

    function getTotalPower() public view returns(uint256) {
        return totalPower;
    }

    function claimReward(uint256 raidIndex) public {
        //characters.processRaidParticipation(charID, victory, xp)
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