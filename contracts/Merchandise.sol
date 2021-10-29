pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./cryptoblades.sol";

contract Merchandise is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    uint256 public constant ITEM_WEAPON_RENAME = 1;

    // every status assumes payment has been made
    uint256 public constant STATUS_SUBMITTED = 0; // fresh order waiting
    uint256 public constant STATUS_SERVICE_ERROR = 1; // bot couldn't place order, can be refunded
    uint256 public constant STATUS_REJECTED = 2; // we've taken personal issue with the order, is refundable
    uint256 public constant STATUS_OFFERED_REFUND = 3; // manually 
    uint256 public constant STATUS_CANCELLED = 1; // was never processed
    uint256 public constant STATUS_PROCESSED = 2; // it's in the system, has shop ID, waiting for completion
    uint256 public constant STATUS_SHIPPED = 3; // shipped (can we even get this info?)

    uint256 public constant VAR_ACCEPTING_ORDERS = 1; // can orders be placed?

    /* ========== STATE VARIABLES ========== */

    CryptoBlades public game;
    IPriceOracle public skillOracle;

    mapping(uint256 => address) public links;
    mapping(uint256 => uint256) public vars;

    /* ========== INITIALIZERS AND MIGRATORS ========== */

    function initialize(CryptoBlades _game, IPriceOracle _skillOracle)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = _game;
        skillOracle = _skillOracle;
    }

    /* ========== VIEWS ========== */

    function getPriceOfItem(uint256 item) public view {
        return 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverToken(address tokenAddress, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier isAdmin() {
         _isAdmin();
        _;
    }
    
    function _isAdmin() internal view {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
    }

}
