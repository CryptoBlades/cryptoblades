pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./shields.sol";
import "./interfaces/IBridgeProxy.sol";


contract ShieldBridgeProxyContract is Initializable, AccessControlUpgradeable, IBridgeProxy {
  
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    Shields shields;
    address nftStorageAddress;
    bool enabled;

    uint8 public constant UINT_NFT_VAR_META = 0;
    uint8 public constant UINT_NFT_VAR_SEED = 1;

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

    function initialize(address _nftStorageAddress, address _shields) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nftStorageAddress = _nftStorageAddress;
        shields = Shields(_shields);
    }

 
    function collectData(uint256 tokenId) external view override returns (uint256[] memory uintVars, bool[] memory boolVars, address[] memory addressVars,  string memory stringVar) {
        
        (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3) = shields.get(tokenId);
        uint8 _type = uint8(shields.getNftVar(tokenId, 2)); // 2 => shield type
        uint256 seed3dCosmetics = shields.getCosmeticsSeed(tokenId);

        uintVars = new uint256[](2);
        uintVars[UINT_NFT_VAR_META] = _packShieldsData(0, _properties, _stat1, _stat2, _stat3, _type);
        uintVars[UINT_NFT_VAR_SEED] = seed3dCosmetics;

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
         tokenId = 
            shields.performMintShieldDetailed(nftStorageAddress, uintVars[UINT_NFT_VAR_META], uintVars[UINT_NFT_VAR_SEED], tokenId);

        return tokenId;
    }

    function _packShieldsData(uint32 appliedCosmetic, uint16 properties, uint16 stat1, uint16 stat2, uint16 stat3, uint8 shieldType) public pure returns (uint256) {
        return  uint256(uint256(shieldType) | uint256(stat3) << 16| (uint256(stat2) << 32) | (uint256(stat1) << 48) | (uint256(properties) << 64) | (uint256(appliedCosmetic) << 80));
    }
}
