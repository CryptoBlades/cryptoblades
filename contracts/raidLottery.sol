pragma solidity ^0.6.0;

import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "./raid.sol";

contract RaidLottery is Raid {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    int128 public entryFee = uint256(1 * 10000).divu(10000); // USD
    uint256 pool = 0;

    constructor(address gameContract) public Raid(gameContract) { }

    function addRaider(address owner, uint256 characterID, uint256 weaponID) public override restricted {

        pool += game.usdToSkill(entryFee);
        //game.payContract(owner, entryFee); // todo expose this with access restriction

        raiders.push(Raider(uint256(owner), characterID, weaponID));
        // we drain ~12h of stamina from the character
        // we may want to have a specific lockout in the future
        characters.setStaminaTimestamp(characterID, uint64(now + (12 * 60 * 60)));
        emit RaiderJoined(owner, characterID, weaponID);
    }
    
    function completeRaid(uint256 seed) public override restricted {
        uint256 winnerIndex = seed % raiders.length;
        Raider memory winner = raiders[winnerIndex];
        skill.transferFrom(address(game), address(winner.owner), pool);
    }
}