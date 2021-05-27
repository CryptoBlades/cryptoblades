pragma solidity ^0.6.5;

interface IRandoms {
    // Views
    function hasRequestedSeed(address user) external view returns (bool);
    function hasReceivedSeed(address user) external view returns (bool);

    // Mutative
    function getRandomNumber(address user) external;
    function consumeSeed(address user) external returns (uint256 seed);

    // Events
    event RandomNumberRequested(address indexed user);
    event RandomNumberReceived(address indexed user);
}
