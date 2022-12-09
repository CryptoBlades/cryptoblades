pragma solidity ^0.6.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library RandomUtil {

    using SafeMath for uint256;

    function randomSeededMinMax(uint min, uint max, uint seed) internal pure returns (uint) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint diff = max.sub(min).add(1);
        uint randomVar = uint(keccak256(abi.encodePacked(seed))).mod(diff);
        randomVar = randomVar.add(min);
        return randomVar;
    }

    function randomSeededMinMaxFast(uint min, uint max, uint seed) internal pure returns (uint) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        // NOTE: doesn't revert from under/overflow or division by zero!
        uint diff = max - min + 1;
        uint randomVar = uint(keccak256(abi.encodePacked(seed))) % diff;
        randomVar = randomVar + min;
        return randomVar;
    }

    function randomSeededMinMaxPrehashed(uint min, uint max, uint hashedSeed) internal pure returns (uint) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        // NOTE: doesn't revert from under/overflow or division by zero!
        // NOTE: the passed seed has to have already been keccak256'd!
        uint diff = max - min + 1;
        uint randomVar = hashedSeed % diff;
        randomVar = randomVar + min;
        return randomVar;
    }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }

    function plusMinus10PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num.div(10);
        return num.sub(tenPercent).add(randomSeededMinMax(0, tenPercent.mul(2), seed));
    }

    function plusMinus10PercentSeededFast(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num/10;
        return num - tenPercent + randomSeededMinMaxFast(0, tenPercent*2, seed);
    }

    function plusMinus10PercentSeededPrehashed(uint256 num, uint256 hashedSeed) internal pure returns (uint256) {
        uint256 tenPercent = num/10;
        return num - tenPercent + randomSeededMinMaxPrehashed(0, tenPercent*2, hashedSeed);
    }

    function plusMinus30PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        // avoid decimal loss
        uint256 thirtyPercent = num.mul(30).div(100);
        return num.sub(thirtyPercent).add(randomSeededMinMax(0, thirtyPercent.mul(2), seed));
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