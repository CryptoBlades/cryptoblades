pragma solidity ^0.6.5;

import "./Cosmetics.sol";
import "./characters.sol";

contract CharacterCosmetics is Cosmetics {

    Characters public characters;

    mapping(uint256 => uint32) public appliedCosmetics;

    event CharacterCosmeticApplied(address indexed owner, uint256 indexed character, uint32 cosmetic);
    event CharacterCosmeticRemoved(address indexed owner, uint256 indexed character, uint32 cosmetic);

    function initialize(Characters _characters)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        characters = _characters;
        for(uint8 i = 1; i < 19; i++) {
            _cosmeticAvailable[i] = true;
        }        
    }

    function applyCosmetic(uint256 characterId, uint32 cosmetic) public {
        require(characters.ownerOf(characterId) == msg.sender, "Not the character owner");
        if(appliedCosmetics[characterId] != _noCosmetic){
            _restoreCosmetic(appliedCosmetics[characterId], 1);
        }

        useCosmetic(cosmetic, 1);

        appliedCosmetics[characterId] = cosmetic;
        emit CharacterCosmeticApplied(msg.sender, characterId, cosmetic);
    }

    function removeCosmetic(uint256 characterId) public {
        require(characters.ownerOf(characterId) == msg.sender, "Not the character owner");
        require(appliedCosmetics[characterId] != _noCosmetic, "No cosmetic applied");
        _restoreCosmetic(appliedCosmetics[characterId], 1);
        emit CharacterCosmeticRemoved(msg.sender, characterId, appliedCosmetics[characterId]);
        appliedCosmetics[characterId] = _noCosmetic;
    }

    function getCharacterCosmetic(uint256 characterId) public view returns (uint32) {
        return appliedCosmetics[characterId];
    }

    function setCharacterCosmetic(uint256 characterId, uint32 cosmetic) public restricted {
        appliedCosmetics[characterId] = cosmetic;
    }
}