pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./CBKLand.sol";
import "./interfaces/IBridgeProxy.sol";


contract CBKLandBridgeProxyContract is Initializable, AccessControlUpgradeable, IBridgeProxy {
  
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CBKLand private _cbkLand;
    address private _nftStorageAddress;
    bool private _enabled;

    uint8 public constant UINT_NFT_VAR_META = 0;
    uint8 public constant UINT_NFT_VAR_ADDRESS = 1;

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

    function initialize(address nftStorageAddress, address cbkLand) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _nftStorageAddress = nftStorageAddress;
        _cbkLand = CBKLand(cbkLand);
    }

 
    // tier, chunkid, x, y, reseller address
    function collectData(uint256 tokenId) external view override returns (uint256[] memory uintVars, string memory stringVar) {
        
        (uint256 tier, uint256 chunkId, uint256 x, uint256 y, address reseller) = _cbkLand.get(tokenId);

        uintVars = new uint256[](2);
        uintVars[UINT_NFT_VAR_META] = _packCBKLandData(tier, chunkId, x, y);
        uintVars[UINT_NFT_VAR_ADDRESS] = uint256(uint160(reseller));
    }

    // for future use, bot will probe the returned value to know if the proxy contract has proper signature behavior
    function sigVersion() external view override returns (uint256) {
        return 3;
    }

    function isEnabled() external view override returns (bool) {
        return _enabled;
    }

    function setEnabled(bool enabled) external restricted {
        _enabled = enabled;
    }

    function mintOrUpdate(address /*receiver*/, uint256 tokenId, uint256[] calldata uintVars, string calldata stringVar) external restricted override returns (uint256) {
        require(_enabled, "not enabled");

        (uint256 tier, uint256 chunkId, uint256 x, uint256 y) = _unpackCBKLandData(uintVars[UINT_NFT_VAR_META]);
        address reseller = address(uint160(uintVars[UINT_NFT_VAR_ADDRESS]));

         tokenId = 
            _cbkLand.mintOrUpdate(tokenId, _nftStorageAddress, tier, chunkId, x, y, reseller);

        return tokenId;
    }

    // tier => 1, 2 or 3 => 8 bits more than enough
    // chunkid => max is 9999 => 16 bits more than enough
    // x => max is 5000 => 16 bits more than enough
    // y => max is 5000 => 16 bits more than enough
    function _packCBKLandData(uint256 tier, uint256 chunkId, uint256 x, uint256 y) internal pure returns (uint256) {
        return  tier | chunkId << 8 | x << 24 | y << 40;
    }

    function _unpackCBKLandData(uint256 metaData) internal pure returns (uint256 tier, uint256 chunkId, uint256 x, uint256 y) {
        tier = metaData & 0xFF;
        chunkId = (metaData >> 8) & 0xFFFF;
        x = (metaData  >> 24) & 0xFFFF;
        y = (metaData >> 40) & 0xFFFF;
    }

    function canBridge(address wallet, uint256 tokenId, uint256 targetChain) external view override returns (bool) {
        return true;
    }
}
