pragma solidity ^0.6.0;

contract Util {
    uint nonce;

    function random(uint min, uint max) internal returns (uint) {
        uint diff = max-min;
        uint random = uint(keccak256(now, msg.sender, nonce)) % diff;
        random += min;
        nonce++;
        return random;
    }
}