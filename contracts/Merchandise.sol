pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./cryptoblades.sol";

contract Merchandise is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint64;

    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    uint256 public constant STATUS_SUBMITTED = 0; // fresh order waiting
    uint256 public constant STATUS_CANCELLED = 1; // cancelled before processing (refunded)
    uint256 public constant STATUS_PROCESSED = 2; // bot has submitted the order to the shop
    uint256 public constant STATUS_ERROR = 3;

    uint256 public constant LINK_SKILL_TOKEN = 1;

    uint256 public constant VAR_ACCEPTING_ORDERS = 1; // can orders be placed?
    uint256 public constant VAR_TRACK_INCOME = 2; // will income go to payouts?

    /* ========== STATE VARIABLES ========== */

    CryptoBlades public game;
    IPriceOracle public skillOracle;

    mapping(uint256 => address) public links;
    mapping(uint256 => uint256) public vars;

    mapping(uint256 => uint256) public itemPrices; // stored in USD cents

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

    function getPriceOfItem(uint256 item) public view returns (uint256) {
        return itemPrices[item] * skillOracle.currentPrice() / 100;
    }

    function getPriceOfBasket(uint256[] memory items, uint8[] memory amounts) returns (uint256) {
        uint256 sumCents = 0;
        for(uint i = 0; i < items.length; i++)
            sumCents = sumCents.add(itemPrices[items[i]]);
        return sumCents.mul(skillOracle.currentPrice()) / 100;
    }
    
    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverToken(address tokenAddress, uint256 amount) external isAdmin {
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function setLink(uint256 linkId, address linkAddress) external isAdmin {
        links[linkId] = linkAddress;
    }

    function setSkillOracle(IPriceOracle newOracle) external isAdmin {
        skillOracle = newOracle;
    }

    function setItemPrice(uint256 item, uint256 usdCents) external restricted {
        itemPrices[item] = usdCents;
    }

    function setItemPrices(uint256[] calldata items, uint256[] prices) external restricted {
        for(uint i = 0; i < items.length; i++)
            itemPrices[items[i]] = prices[i];
    }

    function setItemsToPrice(uint256[] calldata items, uint256 price) external restricted {
        for(uint i = 0; i < items.length; i++)
            itemPrices[items[i]] = prices[i];
    }

    function placeOrder(uint256[] calldata items, uint8[] memory amounts) external returns (uint256) {
        IERC20(links[LINK_SKILL_TOKEN])
            .safeTransferFrom(msg.sender, address(this), getPriceOfBasket(items,amounts));
        return 0; // order ID
    }

    function cancelOrder(uint256 orderId) external {

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
