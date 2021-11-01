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

    uint256 public constant STATUS_SUBMITTED = 0; // fresh order waiting
    uint256 public constant STATUS_CANCELLED = 1; // cancelled before processing (refunded)
    uint256 public constant STATUS_PROCESSED = 2; // bot has submitted the order to the shop
    uint256 public constant STATUS_ERROR = 3;

    uint256 public constant VAR_ACCEPTING_ORDERS = 1; // can orders be placed?
    uint256 public constant VAR_TRACK_INCOME = 2; // will income go to payouts?

    /* ========== STATE VARIABLES ========== */

    CryptoBlades public game;
    IPriceOracle public skillOracle;

    mapping(uint256 => address) public links;
    mapping(uint256 => uint256) public vars;

    mapping(uint256 => uint256) public itemPrices;

    /* ========== INITIALIZERS AND MIGRATORS ========== */

    function initialize(CryptoBlades _game, IPriceOracle _skillOracle)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = _game;
        skillOracle = _skillOracle;

        itemPrices[1] = 199;// TEMP TEST, ERASE
    }

    /* ========== VIEWS ========== */

    function getPriceOfItem(uint256 item) public view returns (uint256) {
        return itemPrices[item] * skillOracle.currentPrice() / 100;
    }
    
    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverToken(address tokenAddress, uint256 amount) public isAdmin {
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function setSkillOracle(IPriceOracle newOracle) public isAdmin {
        skillOracle = newOracle;
    }

    /* ========== MODIFIERS ========== */

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
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
