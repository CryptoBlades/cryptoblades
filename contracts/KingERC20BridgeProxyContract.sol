pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IERC20BridgeProxy.sol";
import "./Promos.sol";


contract KingERC20BridgeProxyContract is Initializable, AccessControlUpgradeable, IERC20BridgeProxy {
  
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    
    Promos public promos;
    bool enabled;

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

    function initialize(Promos _promos) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        promos = _promos;
    }

    // for future use, bot will probe the returned value to know if the proxy contract has proper signature behavior
    function sigVersion() external view override returns (uint256) {
        return 1;
    }

    function isEnabled() external view override returns (bool) {
        return enabled;
    }

    function setEnabled(bool _enabled) external restricted {
        enabled = _enabled;
    }

    function canBridge(address wallet, uint256 amount, uint256 targetChain) external view override returns (bool) {
        return promos.getBit(msg.sender, promos.BIT_BAD_ACTOR()) == false;
    }
}
