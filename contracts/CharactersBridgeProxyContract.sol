pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./CharacterCosmetics.sol";
import "./CharacterRenameTagConsumables.sol";
import "./characters.sol";
import "./interfaces/IBridgeProxy.sol";
import "./Promos.sol";
import "./EquipmentManager.sol";


contract CharactersBridgeProxyContract is Initializable, AccessControlUpgradeable, IBridgeProxy {
  
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    Characters characters;
    CharacterCosmetics characterCosmetics;
    CharacterRenameTagConsumables characterRenameTagConsumables;
    address nftStorageAddress;
    bool enabled;
    bool giveawayGen2Enabled;

    uint8 public constant UINT_NFT_VAR_META = 0;
    uint8 public constant UINT_NFT_VAR_SEED3DCOSMETIC = 1;

    Promos promos;
    EquipmentManager equipmentManager;


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

    function migrate_c906001(Promos _newPromos) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        promos = _newPromos;
    }

    function migrate_68c6936(EquipmentManager _equipmentManager) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        equipmentManager = _equipmentManager;
    }

 
    function collectData(uint256 tokenId) external view override returns (uint256[] memory uintVars,  string memory stringVar) {
        string memory rename = characterRenameTagConsumables.getCharacterRename(tokenId);
        uintVars = new uint256[](2);
        (uintVars[UINT_NFT_VAR_META], uintVars[UINT_NFT_VAR_SEED3DCOSMETIC], stringVar) = _packedCharacterData(tokenId);

        stringVar = rename;
    }

    // for future use, bot will probe the returned value to know if the proxy contract has proper signature behavior
    function sigVersion() external view override returns (uint256) {
        return 3;
    }

    function isEnabled() external view override returns (bool) {
        return enabled;
    }

    function setEnabled(bool _enabled) external restricted {
        enabled = _enabled;
    }

    function mintOrUpdate(address receiver, uint256 tokenId, uint256[] calldata uintVars,  string calldata stringVar) external restricted override returns (uint256) {
        require(enabled, "not enabled");

        (uint32 appliedCosmetic, uint16 xp, uint8 level, uint16 traitAndVersion, uint24 bonusPower, uint16 reputation) = _unpackCharactersData(uintVars[UINT_NFT_VAR_META]); 

        tokenId =  _mintOrUpdate(tokenId, xp, level, traitAndVersion, uintVars[UINT_NFT_VAR_SEED3DCOSMETIC], bonusPower, reputation);
        
        if(appliedCosmetic > 0) {
            characterCosmetics.setCharacterCosmetic(tokenId, uint32(appliedCosmetic));
        }

        if(bytes(stringVar).length > 0) {
            characterRenameTagConsumables.setName(tokenId, stringVar);
        }

        return tokenId;
    }

    function _mintOrUpdate(uint256 tokenId, uint16 xp, uint8 level, uint16 traitAndVersion, uint256 seed, uint24 bonusPower, uint16 reputation) internal returns (uint256) {
        tokenId = 
            characters.customMint(nftStorageAddress, xp, level, uint8(traitAndVersion & 0xFF), seed, tokenId, bonusPower, reputation, uint8((traitAndVersion >> 8) & 0xFF));

        return tokenId;
    }

    function _unpackCharactersData(uint256 metaData) internal pure returns (uint32 appliedCosmetic, uint16 xp, uint8 level, uint16 traitAndVersion, uint24 bonusPower, uint16 reputation) {
        traitAndVersion = uint16((metaData) & 0xFFFF);
        level = uint8((metaData >> 16) & 0xFF);
        xp = uint16(metaData  >> 24 & 0xFFFF);
        appliedCosmetic = uint32((metaData >> 40) & 0xFFFFFFFF);
        bonusPower = uint24((metaData >> 72) & 0xFFFFFF);
        reputation = uint16((metaData >> 96) & 0xFFFF);
    }


    function _packedCharacterData(uint256 characterId) internal view returns (uint256 packedData, uint256 seed3dCosmetics, string memory rename) {
        (uint16 xp, uint8 level, uint8 trait,,,,,,,) = characters.get(characterId);
        uint32 appliedCosmetic = characterCosmetics.getCharacterCosmetic(characterId);
        rename = characterRenameTagConsumables.getCharacterRename(characterId);
        seed3dCosmetics = characters.getCosmeticsSeed(characterId);
        uint24 bonusPower = uint24(characters.getNftVar(characterId, 2)); // 2 => bonus Power
        uint16 reputation = uint16(characters.getNftVar(characterId, 103)); // 103 => reputation
        uint8 version = uint8(characters.getNftVar(characterId, 3)); // 3 => version
        packedData = _packCharactersData(appliedCosmetic, xp, level, uint16(trait | (version << 8)), bonusPower, reputation);
    }

    function _packCharactersData(uint32 appliedCosmetic, uint16 xp, uint8 level, uint16 traitAndVersion, uint24 bonusPower, uint16 reputation) internal pure returns (uint256) {
        return  uint256(uint256(traitAndVersion) | (uint256(level) << 16) | (uint256(xp) << 24) | (uint256(appliedCosmetic) << 40) | (uint256(bonusPower) << 72) | (uint256(reputation) << 96));
    }

    function canBridge(address wallet, uint256 tokenId, uint256 targetChain) external view override returns (bool) {
        return characters.getNftVar(tokenId, 3) == 0 // Only gen 1 is allowed
        && equipmentManager.getNftVar(address(characters), tokenId, 1) == 0; // Nothing equipped
    }
}
