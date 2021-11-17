pragma solidity ^0.6.5;

import "./Consumables.sol";
import "./characters.sol";
import "./interfaces/IRandoms.sol";

contract SmokeBombConsumables is Consumables {

    Characters characters;
    IRandoms public randoms;

    event SmokeBombUsed(address indexed owner, uint256 indexed character);

    function initialize(Characters _characters)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;

        characters = _characters;
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        randoms = _newRandoms;
    }

    function useSmokeBomb(uint256 characterId) public {
        require(characters.ownerOf(characterId) == msg.sender, "Not the character owner");
        consumeItem(1);
        characters.incrementStaminaTimeStamp(characterId, 1);
        emit SmokeBombUsed(msg.sender, characterId);
    }
}