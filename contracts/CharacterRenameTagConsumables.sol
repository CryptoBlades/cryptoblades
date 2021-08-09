pragma solidity ^0.6.5;

import "./Consumables.sol";
import "./characters.sol";

contract CharacterRenameTagConsumables is Consumables {

    Characters characters;

    mapping(uint256 => string) public renames;

    event CharacterRenamed(address indexed owner, uint256 indexed character);

    function initialize(Characters _characters)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;

        characters = _characters;
    }

    function renameCharacter(uint256 characterId, string memory newName) public {
        require(bytes(newName).length < 16, 'too long');
        require(characters.ownerOf(characterId) == msg.sender, "Not the character owner");
        consumeItem();
        renames[characterId] = newName;
        emit CharacterRenamed(msg.sender, characterId);
    }

    function getCharacterRename(uint256 characterId) public view returns (string memory) {
        return renames[characterId];
    }
}
