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

    function randomUnsafeMinMax(uint min, uint max) internal returns (uint) {
        return randomSeededMinMax(min, max, unsafeRandom());
    }
    
    function randomSeeded(uint seed) internal pure returns (uint) {
        // deterministic
        // you can combine seeds before passing to get pseudorandom
        return uint(keccak256(abi.encodePacked(seed)));
    }

    function sliceSeed(uint seed, uint slice, uint div, uint mod) internal pure returns (uint) {
        // a way to cheaply extract more results from a seed without re-rolling it
        // example: (seed, 10000, 100, 25) skips last two digits of seed and gets a 0-24 from from the new end
        // WARNING: distribution of results may not be even!
        // For even distribution use whole multiples of mod for the number of decimals at work (ie 2 digits with mod 4)
        return ((seed % slice) / div) % mod;
    }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }
    
    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }
    
    function unsafeRandom() internal returns (uint) {
        //todo replace this with a library
        uint seed = randomSeeded(combineSeeds(now, nonce));
        nonce = nonce + 1;
        return seed;
    }

    function plusMinus10Percent(uint256 num) internal returns (uint256) {
        uint256 tenPercent = num / 10;
        return num - tenPercent + (randomUnsafeMinMax(0, tenPercent * 2));
    }

    function plusMinus10PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num / 10;
        return num - tenPercent + (randomSeededMinMax(0, tenPercent * 2, seed));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}