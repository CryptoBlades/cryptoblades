pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./items/Junk.sol";
import "./interfaces/IBridgeProxy.sol";


contract JunkBridgeProxyContract is Initializable, AccessControlUpgradeable, IBridgeProxy {
  
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    Junk junk;
    address nftStorageAddress;
    bool enabled;

    uint8 public constant UINT_NFT_VAR_META = 0;

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

    function initialize(address _nftStorageAddress, address _junk) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nftStorageAddress = _nftStorageAddress;
        junk = Junk(_junk);
    }

 
    function collectData(uint256 tokenId) external view override returns (uint256[] memory uintVars, string memory stringVar) {
        
        (uint8 _stars) = junk.get(tokenId);

        uintVars = new uint256[](1);
        uintVars[UINT_NFT_VAR_META] = _packJunkData(_stars);
    }

    // for future use, bot will probe the returned value to know if the proxy contract has proper signature behavior
    function sigVersion() external view override returns (uint256) {
        return 2;
    }

    function isEnabled() external view override returns (bool) {
        return enabled;
    }

    function setEnabled(bool _enabled) external restricted {
        enabled = _enabled;
    }

    function mintOrUpdate(address /*receiver*/, uint256 tokenId, uint256[] calldata uintVars, string calldata stringVar) external restricted override returns (uint256) {
        require(enabled, "not enabled");

         tokenId = 
            junk.performMintJunkDetailed(nftStorageAddress, uintVars[UINT_NFT_VAR_META], tokenId);

        return tokenId;
    }

    function _packJunkData(uint8 stars) public pure returns (uint256) {
        return  uint256(stars);
    }

    function canBridge(address wallet, uint256 tokenId, uint256 targetChain) external view override returns (bool) {
        return true;
    }
}
