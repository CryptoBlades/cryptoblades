pragma solidity ^0.6.5;

interface IRandoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);
    function getRandomSeedUsingHash(address user, bytes32 hash) external view returns (uint256 seed);

    function getHistoricalBlockHash(uint blockNumber) external returns (bytes32);
    function getHistoricalBlockHashWithFallback(uint blockNumber) external returns (bytes32);
    function updateBlockHashes() external;
}
