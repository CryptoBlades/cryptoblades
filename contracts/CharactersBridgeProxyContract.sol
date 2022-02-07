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

    uint8 public constant UINT_NFT_VAR_XP = 0;
    uint8 public constant UINT_NFT_VAR_LEVEL = 1;
    uint8 public constant UINT_NFT_VAR_TRAIT = 2;
    uint8 public constant UINT_NFT_VAR_COSMETIC = 3;
    uint8 public constant UINT_NFT_VAR_SEED3DCOSMETIC = 4;
    uint8 public constant UINT_NFT_VAR_BONUSPOWER = 5;

    uint8 public constant STRING_NFT_VAR_XP = 0;


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

 
    function collectData(uint256 tokenId) external view override returns (uint256[] memory uintVars, bool[] memory boolVars, address[] memory addressVars,  string memory stringVar) {
        (uint16 xp, uint8 level, uint8 trait,,,,,,, ) = characters.get(tokenId);
        uint32 appliedCosmetic = characterCosmetics.getCharacterCosmetic(tokenId);
        string memory rename = characterRenameTagConsumables.getCharacterRename(tokenId);
        uint256 seed3dCosmetics = characters.getCosmeticsSeed(tokenId);
        uint24 bonusPower = uint24(characters.getNftVar(tokenId, 2)); // 2 => bonus Power
        uintVars = new uint256[](6);
        uintVars[UINT_NFT_VAR_XP] = xp;
        uintVars[UINT_NFT_VAR_LEVEL] = level;
        uintVars[UINT_NFT_VAR_TRAIT] = trait;
        uintVars[UINT_NFT_VAR_COSMETIC] = appliedCosmetic;
        uintVars[UINT_NFT_VAR_SEED3DCOSMETIC] = seed3dCosmetics;
        uintVars[UINT_NFT_VAR_BONUSPOWER] = bonusPower;

        stringVar = rename;

        boolVars = new bool[](0);
        addressVars = new address[](0);
    }

    function isEnabled() external view override returns (bool) {
        return enabled;
    }

    function setEnabled(bool _enabled) external restricted {
        enabled = _enabled;
    }

    function mintOrUpdate(uint256 tokenId, uint256[] calldata uintVars, bool[] calldata boolVars, address[] calldata addressVars,  string calldata stringVar) external restricted override returns (uint256) {
        tokenId =  _mintOrUpdate(tokenId, uint16(uintVars[UINT_NFT_VAR_XP]), uint8(uintVars[UINT_NFT_VAR_LEVEL]), uint8(uintVars[UINT_NFT_VAR_TRAIT]), uintVars[UINT_NFT_VAR_SEED3DCOSMETIC], uint24(uintVars[UINT_NFT_VAR_BONUSPOWER]));

        if(uintVars[UINT_NFT_VAR_COSMETIC] > 0) {
            characterCosmetics.setCharacterCosmetic(tokenId, uint32(uintVars[UINT_NFT_VAR_COSMETIC]));
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
}
