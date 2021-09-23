pragma solidity ^0.6.5;

import "./Consumables.sol";
import "./characters.sol";

contract CharacterLightningTraitChangeConsumables is Consumables {

    Characters characters;

    event CharacterTraitChangedToLightning(address indexed owner, uint256 indexed character, uint8 from);

    function initialize(Characters _characters)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;

        characters = _characters;
    }

    function changeCharacterTrait(uint256 characterId) public {
        require(characters.ownerOf(characterId) == msg.sender, "Not the character owner");
        consumeItem(1);
        emit CharacterTraitChangedToLightning(msg.sender, characterId, characters.getTrait(characterId));
        characters.setTrait(characterId, 2);
    }
}
