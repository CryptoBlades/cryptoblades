pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./WeaponCosmetics.sol";
import "./WeaponRenameTagConsumables.sol";
import "./weapons.sol";
import "./interfaces/IBridgeProxy.sol";


contract WeaponBridgeProxyContract is Initializable, AccessControlUpgradeable, IBridgeProxy {
  
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    Weapons weapons;
    WeaponCosmetics weaponCosmetics;
    WeaponRenameTagConsumables weaponRenameTagConsumables;
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

    function initialize(address _nftStorageAddress, address _weapons, address _weaponCosmetics, address _weaponRenameTagConsumables) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nftStorageAddress = _nftStorageAddress;
        weapons = Weapons(_weapons);
        weaponCosmetics = WeaponCosmetics(_weaponCosmetics);
        weaponRenameTagConsumables = WeaponRenameTagConsumables(_weaponRenameTagConsumables);
    }

 
    function collectData(uint256 tokenId) external view override returns (uint256[] memory uintVars, string memory stringVar) {
        
        (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level,,,,, uint24 _burnPoints,) = weapons.get(tokenId);
        uint32 appliedCosmetic = weaponCosmetics.getWeaponCosmetic(tokenId);
        string memory rename = weaponRenameTagConsumables.getWeaponRename(tokenId);
        uint256 seed3dCosmetics = weapons.getCosmeticsSeed(tokenId);

        uintVars = new uint256[](2);
        uintVars[UINT_NFT_VAR_META] = _packWeaponsData(appliedCosmetic, _properties, _stat1, _stat2, _stat3, _level, uint8(_burnPoints & 0xFF), uint8((_burnPoints >> 8) & 0xFF), uint8((_burnPoints >> 16) & 0xFF));
        uintVars[UINT_NFT_VAR_SEED3DCOSMETIC] = seed3dCosmetics;

        stringVar = rename;
    }

    function isEnabled() external view override returns (bool) {
        return enabled;
    }

    function setEnabled(bool _enabled) external restricted {
        enabled = _enabled;
    }

    function mintOrUpdate(uint256 tokenId, uint256[] calldata uintVars, string calldata stringVar) external restricted override returns (uint256) {
        require(enabled, "not enabled");

        uint32 appliedCosmetic = uint32((uintVars[UINT_NFT_VAR_META] >> 96) & 0xFFFFFFFF);

         tokenId = 
            weapons.performMintWeaponDetailed(nftStorageAddress, uintVars[UINT_NFT_VAR_META], uintVars[UINT_NFT_VAR_SEED3DCOSMETIC], tokenId);

        if(appliedCosmetic > 0) {
            weaponCosmetics.setWeaponCosmetic(tokenId, appliedCosmetic);
        }

        if(bytes(stringVar).length > 0) {
            weaponRenameTagConsumables.setName(tokenId, stringVar);
        }

        return tokenId;
    }

    function _packWeaponsData(uint32 appliedCosmetic, uint16 properties, uint16 stat1, uint16 stat2, uint16 stat3, uint8 weaponLevel, uint8 lowStarBurnPoints, uint8 fourStarBurnPoints, uint8 fiveStarBurnPoints) internal pure returns (uint256) {
        return  uint256(fiveStarBurnPoints | (uint256(fourStarBurnPoints) << 8) | (uint256(lowStarBurnPoints) << 16) | (uint256(weaponLevel) << 24) | (uint256(stat3) << 32) | (uint256(stat2) << 48) | (uint256(stat1) << 64) | (uint256(properties) << 80) | (uint256(appliedCosmetic) << 96));
    }
}
