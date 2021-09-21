pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./raid.sol";

contract RaidBasic is Initializable, Raid {

    // THIS AND raid.sol are old unused files, DO NOT USE!

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    uint64 internal staminaDrain;
    uint256[] weaponDrops; // given out randomly, we add them manually
    uint256 bounty; // UNUSED; KEPT FOR UPGRADE PROXY BACKWARDS COMPAT
    uint8 bossTrait; // set manually for now

    uint256 totalPower;

    event XpReward(address addr, uint256 charID, uint256 amount);
    event WeaponWinner(address addr, uint256 wepID);

    function initialize(address gameContract) public override initializer {
        Raid.initialize(gameContract);

        staminaDrain = 12 * 60 * 60;
    }

    function addRaider(uint256 characterID, uint256 weaponID) public override {
        require(characters.ownerOf(characterID) == msg.sender);
        require(weapons.ownerOf(weaponID) == msg.sender);
        require(participation[characterID] == false, "This character is already part of the raid");

        participation[characterID] = true;
        // we drain ~12h of stamina from the character
        // we may want to have a specific lockout in the future
        int128 traitMultiplier = 0;
        uint24 power = 0;
        totalPower += power;
        raiders.push(Raider(uint256(msg.sender), characterID, weaponID, power));
        emit RaiderJoined(msg.sender, characterID, weaponID, power);
    }

    function completeRaid(uint256 seed) public override restricted {
        require(completed == false, "Raid already completed, run reset first");
        completed = true;

        emit RaidCompleted();
    }

    function reset() public override restricted {
        totalPower = 0;
        delete weaponDrops;
        super.reset();
    }

    function setBossTrait(uint8 trait) public restricted {
        bossTrait = trait;
    }

    function getTotalPower() public view returns(uint256) {
        return totalPower;
    }

    function getWeaponDrops() public view returns(uint256[] memory) {
        return weaponDrops;
    }

    function setStaminaDrainSeconds(uint64 secs) public restricted {
        staminaDrain = secs;
    }

    function getStaminaDrainSeconds() public view returns(uint64) {
        return staminaDrain;
    }
}