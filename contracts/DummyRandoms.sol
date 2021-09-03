pragma solidity ^0.6.5;

import "./interfaces/IRandoms.sol";
import "./HasMain.sol";

contract DummyRandoms is IRandoms, HasMain {
    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(address => bool) private alreadyRequestedTestingFlag;
    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(address => bool) private seedAvailable;
    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(address => uint256) private seeds;

    uint256 private seed;

    function initialize() public initializer {
        __HasMain_init();
    }

    // Views
    function getRandomSeed(address user) external view override returns (uint256) {
        return uint256(keccak256(abi.encodePacked(user, seed, block.timestamp)));
    }

    function getRandomSeedUsingHash(address user, bytes32 hash) external view override returns (uint256) {
        return uint256(keccak256(abi.encodePacked(user, seed, hash, block.timestamp)));
    }

    // Mutative
    function setRandomNumberForTestingPurposes(uint256 randomValue) external {
        seed = randomValue;
    }
}
