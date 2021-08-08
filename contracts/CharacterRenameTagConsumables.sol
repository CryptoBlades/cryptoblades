pragma solidity ^0.6.5;

import "./Consumables.sol";

contract CharacterRenameTagConsumables is Consumables {

    mapping(uint256 => string) public renames;

    event CharacterRenamed(address indexed owner, uint256 indexed weapon);

    function renameCharacter(uint256 characterId, string memory newName) public {
        require(bytes(newName).length < 16, 'too long');
        consumeItem();
        renames[characterId] = newName;
        emit CharacterRenamed(msg.sender, characterId);
    }

    function getCharacterRename(uint256 characterId) public view returns (string memory) {
        return renames[characterId];
    }
}
