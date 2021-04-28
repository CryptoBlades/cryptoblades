pragma solidity ^0.6.0;

import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "./raid.sol";

contract RaidBasic is Raid, Util {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    uint64 internal staminaDrain = 12 * 60 * 60;
    uint256[] weaponDrops; // given out randomly, we add them manually
    uint256 bounty; // split based on power

    event SkillWinner(address addr, uint256 amount);
    event WeaponWinner(address addr, uint256 wepID);

    constructor(address gameContract) public Raid(gameContract) { }

    function addRaider(address owner, uint256 characterID, uint256 weaponID) public override restricted {
        require(participation[characterID] == false, "This character is already part of the raid");
        require(characters.getStaminaPoints(characterID) > 0, "You cannot join with 0 stamina");

        participation[characterID] = true;
        // we drain ~12h of stamina from the character
        // we may want to have a specific lockout in the future
        characters.setStaminaTimestamp(characterID, uint64(now + (staminaDrain)));

        uint24 power = game.getPlayerPower(characterID, weaponID);
        raiders.push(Raider(uint256(owner), characterID, weaponID, power));
        emit RaiderJoined(owner, characterID, weaponID, power);
    }
    
    function completeRaid(uint256 seed) public override restricted {
        require(completed == false, "Raid already completed, run reset first");
        completed = true;
        uint256 totalPower = 0;
        for(uint i = 0; i < raiders.length; i++) {
            Raider memory r = raiders[i];
            totalPower += r.power;
        }
        
        for(uint i = 0; i < raiders.length; i++) {
            Raider memory r = raiders[i];
            
            int128 powerPercentage = totalPower.divu(r.power);
            uint256 payout = powerPercentage.mulu(bounty);
            game.payPlayerConverted(address(r.owner), payout);
            emit SkillWinner(address(r.owner), payout);
        }

        for(uint i = 0; i < weaponDrops.length; i++) {
            Raider memory r = raiders[randomSeededMinMax(0, raiders.length-1, combineSeeds(seed,i))];
            game.approveContractWeaponFor(weaponDrops[i], address(this));
            weapons.transferFrom(address(game), address(r.owner), weaponDrops[i]);
            emit WeaponWinner(address(r.owner), weaponDrops[i]);
        }
        
        emit RaidCompleted();
    }

    function setBounty(uint256 to) public restricted {
        bounty = to;
    }

    function getBounty() public view returns(uint256) {
        return bounty;
    }

    function addRewardWeapon(uint256 id) public restricted {
        require(weapons.ownerOf(id) == address(game), "Can only add weapons that belong to the main game contract");
        weaponDrops.push(id);
    }

    function mintRewardWeapon(uint256 stars, uint256 seed) public restricted {
        uint256 tokenId = weapons.mintWeaponWithStars(address(game), stars, seed);
        addRewardWeapon(tokenId);
    }

    function setStaminaDrainSeconds(uint64 secs) public restricted {
        staminaDrain = secs;
    }

    function getStaminaDrainSeconds() public view returns(uint64) {
        return staminaDrain;
    }
}