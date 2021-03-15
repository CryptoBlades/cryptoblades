pragma solidity ^0.6.0;

import "./util.sol";

contract Data is Util {

    uint256 public maxStamina = 200;
    uint256 public secondsPerStamina = 300; //5 * 60
    
    uint256 public mintCharacterFee = 500;
    uint256 public rerollTraitFee = 300;
    uint256 public rerollCosmeticsFee = 300;
    uint256 public refillStaminaFee = 1000;
    
    uint256 public mintWeaponFee = 200;
    uint256 public reforgeWeaponFee = 100;

    function getStaminaMaxWait() public view returns (uint64) {
        return uint64(maxStamina * secondsPerStamina);
    }

    

}