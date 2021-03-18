pragma solidity ^0.6.0;

import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";

contract Util {
    
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for uint16;

    uint nonce;

    function randomSeededMinMax(uint min, uint max, uint seed) internal pure returns (uint) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint diff = (max-min) + 1;
        uint randomVar = uint(keccak256(abi.encodePacked(seed))) % diff;
        randomVar += min;
        return randomVar;
    }

    function randomSafeMinMax(uint min, uint max) internal returns (uint) {
        return randomSeededMinMax(min, max, safeRandom());
    }
    
    function randomSeeded(uint seed) internal pure returns (uint) {
        // deterministic
        // you can combine seeds before passing to get pseudorandom
        return uint(keccak256(abi.encodePacked(seed)));
    }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }
    
    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }
    
    function safeRandom() internal returns (uint) {
        //todo replace this with a library
        uint seed = randomSeeded(combineSeeds(now, nonce));
        nonce = nonce + 1;
        return seed;
    }

    function plusMinus10Percent(uint256 num) internal returns (uint256) {
        uint256 tenPercent = num / 10;
        return num - tenPercent + (randomSafeMinMax(0, tenPercent * 2));
    }

    function plusMinus10PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num / 10;
        return num - tenPercent + (randomSeededMinMax(0, tenPercent * 2, seed));
    }

}