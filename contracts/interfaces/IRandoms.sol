pragma solidity ^0.6.5;

interface IRandoms {
    // Views
    function hasRequestedSeed(address user) external view returns (bool);
    function hasConsumableSeed(address user) external view returns (bool);

    // Mutative
    function getRandomNumber(address user, uint256 userProvidedSeed) external;
    function consumeSeed(address user) external returns (uint256);

    // Events
    event RandomNumberRequested(address indexed user, uint256 userProvidedSeed);
    event RandomNumberReceived(address indexed user);
}
