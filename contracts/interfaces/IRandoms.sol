pragma solidity ^0.6.5;

interface IRandoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);
    function getRandomSeed2(address user, uint256 seed2) external view returns (uint256 seed);
}
