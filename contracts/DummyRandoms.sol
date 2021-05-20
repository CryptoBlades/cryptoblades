pragma solidity ^0.6.5;

import "./interfaces/IRandoms.sol";
import "./HasMain.sol";

contract DummyRandoms is IRandoms, HasMain {
    mapping(address => bool) private seedAvailable;
    mapping(address => uint256) private seeds;

    function initialize() public initializer {
        __HasMain_init();
    }

    // Mutative
    function getRandomNumber(address user) external override {
        uint256 fakeRandomValue =
            uint256(keccak256(abi.encodePacked(block.timestamp, user)));
        seeds[user] = fakeRandomValue;
        seedAvailable[user] = true;
    }

    function consumeSeed(address user) external override returns (uint256) {
        require(seedAvailable[user], "User has no random seed");
        uint256 seed = seeds[user];
        delete seeds[user];
        delete seedAvailable[user];
        return seed;
    }

    function setRandomNumberForUserForTestingPurposes(
        address user,
        uint256 randomValue
    ) external {
        seeds[user] = randomValue;
        seedAvailable[user] = true;
    }
}
