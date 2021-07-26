pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./multiAccessUpgradeable.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract Raid is Initializable, MultiAccessUpgradeable {

    // Outline raids contract that we can iterate on and deploy multiple of.
    // Needs to be granted access to NFT contracts to interact with them

    bool internal completed;
    uint256 internal expectedFinishTime; // not a guarantee since we don't automate this (atm)

    CryptoBlades internal game;
    Characters internal characters;
    Weapons internal weapons;

    struct Raider {
        uint256 owner;
        uint256 charID;
        uint256 wepID;
        uint24 power;
    }
    Raider[] internal raiders;
    mapping(uint256 => bool) internal participation;

    event RaidReset();
    event RaiderJoined(address owner, uint256 character, uint256 weapon, uint24 power);
    event RaidCompleted();

    function initialize(address gameContract) public virtual initializer {
        MultiAccessUpgradeable.initialize();

        grantAccess(gameContract);
        game = CryptoBlades(gameContract);
        // maybe just use extra params for NFT addresses?
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
    }

    function reset() public virtual restricted {
        for(uint i = 0; i < raiders.length; i++) {
            delete participation[raiders[i].charID]; // we cant clear all mappings in one delete call
        }
        delete raiders;
        completed = false;
        emit RaidReset();
    }

    function isRaider(uint256 character) public view returns(bool) {
        return participation[character];
    }

    function getRaiderCount() public view returns(uint256) {
        return raiders.length;
    }

    function getExpectedFinishTime() public view returns(uint256) {
        return expectedFinishTime;
    }

    function setExpectedFinishTime(uint256 time) public restricted {
        expectedFinishTime = time;
    }

    function addRaider(uint256 characterID, uint256 weaponID) public virtual;
    function completeRaid(uint256 seed) public virtual;
}