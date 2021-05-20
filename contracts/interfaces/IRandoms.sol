pragma solidity ^0.6.5;

interface IRandoms {
    // Mutative
    function getRandomNumber(address user) external;
    function consumeSeed(address user) external returns (uint256 seed);

    // Events
    event RandomNumberRequested(address indexed user);
    event RandomNumberReceived(address indexed user);
}
