pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./CharacterCosmetics.sol";
import "./CharacterRenameTagConsumables.sol";
import "./characters.sol";


contract CharactersBridgeProxyContract is Initializable, AccessControlUpgradeable, IBridgeableNFT {
  
    Characters _characters;
    CharacterCosmetics _characterCosmetics;
    CharacterRenameTagConsumables _characterRenameTagConsumables;

    uint8 public constant UINT_NFT_VAR_XP = 0;
    uint8 public constant UINT_NFT_VAR_LEVEL = 1;
    uint8 public constant UINT_NFT_VAR_TRAIT = 2;
    uint8 public constant UINT_NFT_VAR_COSMETIC = 3;
    uint8 public constant UINT_NFT_VAR_SEED3DCOSMETIC = 4;
    uint8 public constant UINT_NFT_VAR_BONUSPOWER = 5;

    uint8 public constant STRING_NFT_VAR_XP = 0;



    function initialize(address characters, address characterCosmetics, address characterRenameTagConsumables) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _characters = Characters(characters);
        _characterCosmetics = CharacterCosmetics(characterCosmetics);
        _characterRenameTagConsumables = CharacterRenameTagConsumables(characterRenameTagConsumables);
    }

 
    function collectData(uint256 tokenId) external view returns (uint256[] memory uintVars, bool[] memory boolVars, address[] memory addressVars,  string[] memory stringVars) {
        (uint16 xp, uint8 level, uint8 trait,,,,,,, ) = characters.get(tokenId);
        uint32 appliedCosmetic = characterCosmetics.getCharacterCosmetic(tokenId);
        rename = characterRenameTagConsumables.getCharacterRename(tokenId);
        seed3dCosmetics = characters.getCosmeticsSeed(tokenId);
        uint24 bonusPower = uint24(characters.getNftVar(tokenId, 2)); // 2 => bonus Power
        uintVars = new uint256[](6);
        uintVars[UINT_NFT_VAR_XP] = xp;
        uintVars[UINT_NFT_VAR_LEVEL] = level;
        uintVars[UINT_NFT_VAR_TRAIT] = trait;
        uintVars[UINT_NFT_VAR_COSMETIC] = appliedCosmetic;
        uintVars[UINT_NFT_VAR_SEED3DCOSMETIC] = seed3dCosmetics;
        uintVars[UINT_NFT_VAR_BONUSPOWER] = bonusPower;

        stringVars = new string[](1);
        stringVars[STRING_NFT_VAR_XP] = rename;

        boolVars = new bool[](0);
        addressVars = new address[](0);
    }

    function mintOrUpdate(uint256 tokenId, uint256[] calldata uintVars, bool[] calldata boolVars, address[] calldata addressVars,  string[] calldata stringVars) returns (uint256) {
        (uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait, uint24 bonusPower, uint256 seed) = 
            (uintVars[UINT_NFT_VAR_COSMETIC], uintVars[UINT_NFT_VAR_XP], uintVars[UINT_NFT_VAR_LEVEL], uintVars[UINT_NFT_VAR_TRAIT], uintVars[UINT_NFT_VAR_BONUSPOWER], uintVars[UINT_NFT_VAR_SEED3DCOSMETIC]);
        
        tokenId = characters.customMint(address(this), xp, level, trait, seed, tokenId, bonusPower);

        if(appliedCosmetic > 0) {
            characterCosmetics.setCharacterCosmetic(tokenId, appliedCosmetic);
        }

        if(bytes(stringVars[STRING_NFT_VAR_XP]).length > 0) {
            characterRenameTagConsumables.setName(tokenId, stringVars[STRING_NFT_VAR_XP]);
        }

        return tokenId;
    }
}
