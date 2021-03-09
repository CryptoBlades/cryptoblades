pragma solidity ^0.6.0;

contract Util {
    uint nonce;

    function random(uint min, uint max) internal returns (uint) {
        uint diff = max-min;
        uint randomVar = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % diff;
        randomVar += min;
        nonce++;
        return randomVar;
    }
    
    function timestampSecondsToStandard(uint64 timestamp) public pure returns (uint256) {
        return uint256(timestamp) * 1 seconds;
    }

    function timestampStandardToSeconds(uint256 timestamp) public pure returns (uint64) {
        return uint64(timestamp / 1 seconds);
    }
}