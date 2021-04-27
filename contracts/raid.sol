pragma solidity ^0.6.0;

import "./multiAccess.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract Raid is MultiAccess {

    // Basic raids contract that we can iterate on and deploy multiple of.
    // Needs to be granted access to NFT contracts to interact with them

    uint256 completeTime;

    CryptoBlades internal game;
    Characters internal characters;
    Weapons internal weapons;
    ERC20 internal skill = ERC20(0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab);

    struct Raider {
        uint256 owner;
        uint256 charID;
        uint256 wepID;
    }
    Raider[] public raiders;

    event RaiderJoined(address owner, uint256 character, uint256 weapon);
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
        completeTime = 0;
    }

    function setCompleteTime(uint256 time) public restricted {
        completeTime = time;
    }

    function getCompleteTime() public view returns(uint256) {
        return completeTime;
    }

    function addRaider(address owner, uint256 characterID, uint256 weaponID) public virtual;
    function completeRaid(uint256 seed) public virtual;
}