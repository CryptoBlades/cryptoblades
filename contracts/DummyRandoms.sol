pragma solidity ^0.6.5;

import "./interfaces/IRandoms.sol";
import "./HasMain.sol";

contract DummyRandoms is IRandoms, HasMain {
    mapping(address => bool) private alreadyRequestedTestingFlag;
    mapping(address => bool) private seedAvailable;
    mapping(address => uint256) private seeds;

    function initialize() public initializer {
        __HasMain_init();
    }

    // Views
    function hasRequestedSeed(address user) external override view returns (bool) {
        return alreadyRequestedTestingFlag[user] || seedAvailable[user];
    }

    function hasReceivedSeed(address user) external override view returns (bool) {
        return seedAvailable[user];
    }

    // Mutative
    function getRandomNumber(address user) external override {
        require(!seedAvailable[user], "Already received");
        require(!alreadyRequestedTestingFlag[user], "Already requested");

        uint256 fakeRandomValue =
            uint256(keccak256(abi.encodePacked(block.timestamp, user)));
        seeds[user] = fakeRandomValue;
        seedAvailable[user] = true;
        emit RandomNumberRequested(user);
        emit RandomNumberReceived(user);
    }

    function consumeSeed(address user)
        external
        override
        restrictedToMain
        returns (uint256)
    {
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
        emit RandomNumberReceived(user);
    }

    function setAlreadyRequestedTestingFlag(address user, bool alreadyRequested)
        external
    {
        alreadyRequestedTestingFlag[user] = alreadyRequested;
    }
}
