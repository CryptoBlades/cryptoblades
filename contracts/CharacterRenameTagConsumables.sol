pragma solidity ^0.6.5;

import "./Consumables.sol";
import "./characters.sol";

contract CharacterRenameTagConsumables is Consumables {

    Characters characters;

    uint8 private _minSize;
    uint8 private _maxSize;

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
        _minSize = 1;
        _maxSize = 24;
    }

    function renameCharacter(uint256 characterId, string memory newName) public {
        require(bytes(newName).length >= _minSize && bytes(newName).length <= _maxSize, 'size not valid');
        require(characters.ownerOf(characterId) == msg.sender, "Not the character owner");
        consumeItem(1);
        renames[characterId] = newName;
        emit CharacterRenamed(msg.sender, characterId);
    }

    function getCharacterRename(uint256 characterId) public view returns (string memory) {
        return renames[characterId];
    }

    function setMinSize(uint8 newMinSize) external isAdmin {
        require(newMinSize > 0, 'invalid size');
        _minSize = newMinSize;
    }

    function setMaxSize(uint8 newMaxSize) external isAdmin {
        require(newMaxSize > 0, 'invalid size');
        _maxSize = newMaxSize;
    }

    function getMinSize() public view returns (uint8){
        return _minSize;
    }

    function getMaxSize() public view returns (uint8){
        return _maxSize;
    }
}