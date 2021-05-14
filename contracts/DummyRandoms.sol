pragma solidity ^0.6.5;

import "./interfaces/IRandoms.sol";
import "./HasMain.sol";

contract DummyRandoms is IRandoms, HasMain {
    mapping(address => bool) private seedAvailable;
    mapping(address => uint256) private seeds;

    function initialize() public initializer {
        __HasMain_init();
    }

    // Views
    function hasRequestedSeed(address user)
        public
        view
        override
        restrictedToMain
        returns (bool)
    {
        // since we immediatelly fulfill with a fake random value,
        // the moment a value is requested, it will also be available for consumption
        return hasConsumableSeed(user);
    }

    function hasConsumableSeed(address user)
        public
        view
        override
        restrictedToMain
        returns (bool)
    {
        return seedAvailable[user];
    }

    // Mutative
    function getRandomNumber(address user, uint256 userProvidedSeed)
        external
        override
        restrictedToMain
    {
        uint256 fakeRandomValue = uint256(keccak256(abi.encodePacked(block.timestamp, user, userProvidedSeed)));
        seeds[user] = fakeRandomValue;
        seedAvailable[user] = true;
    }

    function consumeSeed(address user)
        external
        override
        restrictedToMain
        returns (uint256)
    {
        uint256 seed = seeds[user];
        delete seeds[user];
        delete seedAvailable[user];
        return seed;
    }

    function setRandomNumberForUserForTestingPurposes(address user, uint256 randomValue) external {
        seeds[user] = randomValue;
        seedAvailable[user] = true;
    }
}
