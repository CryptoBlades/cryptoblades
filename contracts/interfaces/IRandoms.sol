pragma solidity ^0.6.5;

interface IRandoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);
}
