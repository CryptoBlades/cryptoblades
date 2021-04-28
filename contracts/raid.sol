pragma solidity ^0.6.0;

import "./multiAccess.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract Raid is MultiAccess {

    // Outline raids contract that we can iterate on and deploy multiple of.
    // Needs to be granted access to NFT contracts to interact with them

    bool internal completed;

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

    constructor(address gameContract) public MultiAccess() {
        grantAccess(gameContract);
        game = CryptoBlades(gameContract);
        // maybe just use extra params for NFT addresses?
        characters = Characters(game.getCharactersAddress());
        weapons = Weapons(game.getWeaponsAddress());
    }

    function reset() public restricted {
        delete raiders;
        delete participation;
        completed = false;
        emit RaidReset();
    }

    function addRaider(address owner, uint256 characterID, uint256 weaponID) public virtual;
    function completeRaid(uint256 seed) public virtual;
}