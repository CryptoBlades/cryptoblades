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

    // NOTE: It was decided to not calculate prices on-chain, so a lot of variables/functions are unused

    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    uint8 public constant STATUS_PAID = 0;

    uint256 public constant LINK_SKILL_TOKEN = 1;

    uint256 public constant VAR_ORDERS_ENABLED = 1; // can orders be placed?
    uint256 public constant VAR_TRACK_INCOME = 2; // will income go to payouts?

    /* ========== STATE VARIABLES ========== */

    CryptoBlades public game;
    IPriceOracle public skillOracle;

    mapping(uint256 => address) public links;
    mapping(uint256 => uint256) public vars;

    mapping(uint256 => uint256) public itemPrices; // stored in USD cents

    uint256 public nextOrderID;
    uint256 public lowestUnprocessedOrderID;
    mapping(uint256 => address) public orderBuyer;
    mapping(uint256 => uint256) public orderPaidAmount;
    mapping(uint256 => uint32[]) public orderBaskets; // 8 bits amount, 24 bits itemID
    mapping(uint256 => uint256) public orderData; // 8 bits status, rest is timestamp (for now)

    event OrderPlaced(address indexed buyer, uint256 indexed orderId, uint256 paid, uint256[] items, uint8[] amounts);
    event OrderSaved(address indexed user, uint256 indexed orderNumber, uint256 payingAmount);
    event OrderStatusChanged(uint256 indexed orderId, uint8 indexed newStatus);

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

    function getUserAllowanceRequired(address user, uint256 charge) public view returns (uint256) {
        uint256 unclaimedSkill = game.getTokenRewardsFor(user);
        return charge < unclaimedSkill ? 0 : charge-unclaimedSkill;
    }

    function canUserBeCharged(address user, uint256 charge) public view returns (bool) {
        uint256 allowanceRequired = getUserAllowanceRequired(user, charge);
        return IERC20(links[LINK_SKILL_TOKEN]).allowance(user, address(game)) >= allowanceRequired;
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

    function createOrder(address user, uint256 orderNumber, uint256 payingAmount) external restricted {
        require(vars[VAR_ORDERS_ENABLED] != 0, "Cannot place orders right now");
        orderBuyer[orderNumber] = user;
        game.payContractTokenOnly(user, payingAmount, vars[VAR_TRACK_INCOME] != 0);
        orderPaidAmount[orderNumber] += payingAmount;

        emit OrderSaved(user, orderNumber, payingAmount);
    }

    function getOrderPaidAmount(uint256 orderNumber) public view returns (uint256) {
        return orderPaidAmount[orderNumber];
    }

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
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
