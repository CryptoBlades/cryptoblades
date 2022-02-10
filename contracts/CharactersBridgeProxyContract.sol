pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./CharacterCosmetics.sol";
import "./CharacterRenameTagConsumables.sol";
import "./characters.sol";
import "./interfaces/IBridgeProxy.sol";


contract CharactersBridgeProxyContract is Initializable, AccessControlUpgradeable, IBridgeProxy {
  
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    Characters characters;
    CharacterCosmetics characterCosmetics;
    CharacterRenameTagConsumables characterRenameTagConsumables;
    address nftStorageAddress;
    bool enabled;

    uint8 public constant UINT_NFT_VAR_META = 0;
    uint8 public constant UINT_NFT_VAR_SEED3DCOSMETIC = 1;


    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

    function initialize(address _nftStorageAddress, address _characters, address _characterCosmetics, address _characterRenameTagConsumables) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nftStorageAddress = _nftStorageAddress;
        characters = Characters(_characters);
        characterCosmetics = CharacterCosmetics(_characterCosmetics);
        characterRenameTagConsumables = CharacterRenameTagConsumables(_characterRenameTagConsumables);
    }

 
    function collectData(uint256 tokenId) external view override returns (uint256[] memory uintVars,  string memory stringVar) {
        (uint16 xp, uint8 level, uint8 trait,,,,,,, ) = characters.get(tokenId);
        uint32 appliedCosmetic = characterCosmetics.getCharacterCosmetic(tokenId);
        string memory rename = characterRenameTagConsumables.getCharacterRename(tokenId);
        uint256 seed3dCosmetics = characters.getCosmeticsSeed(tokenId);
        uint24 bonusPower = uint24(characters.getNftVar(tokenId, 2)); // 2 => bonus Power
        uintVars = new uint256[](2);
        (uintVars[UINT_NFT_VAR_META], uintVars[UINT_NFT_VAR_SEED3DCOSMETIC], stringVar) = _packedCharacterData(tokenId);

        stringVar = rename;
    }

    function isEnabled() external view override returns (bool) {
        return enabled;
    }

    function setEnabled(bool _enabled) external restricted {
        enabled = _enabled;
    }

    function mintOrUpdate(uint256 tokenId, uint256[] calldata uintVars,  string calldata stringVar) external restricted override returns (uint256) {
        require(enabled, "not enabled");

        (uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait, uint24 bonusPower) = _unpackCharactersData(uintVars[UINT_NFT_VAR_META]); 

        tokenId =  _mintOrUpdate(tokenId, xp, level, trait, uintVars[UINT_NFT_VAR_SEED3DCOSMETIC], bonusPower);
        
        if(appliedCosmetic > 0) {
            characterCosmetics.setCharacterCosmetic(tokenId, uint32(appliedCosmetic));
        }

        if(bytes(stringVar).length > 0) {
            characterRenameTagConsumables.setName(tokenId, stringVar);
        }

        return tokenId;
    }

    function _mintOrUpdate(uint256 tokenId, uint16 xp, uint8 level, uint8 trait, uint256 seed, uint24 bonusPower) internal returns (uint256) {
        tokenId = 
            characters.customMint(nftStorageAddress, xp, level, trait, seed, tokenId, bonusPower);

        return tokenId;
    }

    function _unpackCharactersData(uint256 metaData) internal pure returns (uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait, uint24 bonusPower) {
        trait = uint8((metaData) & 0xFF);
        level = uint8((metaData >> 8) & 0xFF);
        xp = uint16(metaData  >> 16 & 0xFFFF);
        appliedCosmetic = uint32((metaData >> 32) & 0xFFFFFFFF);
        bonusPower = uint24((metaData >> 64) & 0xFFFFFF);
    }


    function _packedCharacterData(uint256 characterId) internal view returns (uint256 packedData, uint256 seed3dCosmetics, string memory rename) {
        (uint16 xp, uint8 level, uint8 trait,,,,,,, ) = characters.get(characterId);
        uint32 appliedCosmetic = characterCosmetics.getCharacterCosmetic(characterId);
        rename = characterRenameTagConsumables.getCharacterRename(characterId);
        seed3dCosmetics = characters.getCosmeticsSeed(characterId);
        uint24 bonusPower = uint24(characters.getNftVar(characterId, 2)); // 2 => bonus Power
        packedData = _packCharactersData(appliedCosmetic, xp, level, trait, bonusPower);
    }

    function _packCharactersData(uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait, uint24 bonusPower) internal pure returns (uint256) {
        return  uint256(uint256(trait) | (uint256(level) << 8) | (uint256(xp) << 16) | (uint256(appliedCosmetic) << 32) | (uint256(bonusPower) << 64));
    }
}
