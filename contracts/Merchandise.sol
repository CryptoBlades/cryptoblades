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

    uint8 public constant STATUS_SUBMITTED = 0; // fresh order waiting
    uint8 public constant STATUS_CANCELLED = 1; // cancelled before processing (refunded)
    uint8 public constant STATUS_PROCESSED = 2; // bot has submitted the order to the shop
    uint8 public constant STATUS_PAUSED = 3; // something happened, can not be refunded
    uint8 public constant STATUS_ERROR_REFUNDABLE = 4; // something happened, can be refunded

    //uint256 public constant LINK_ = 1;

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

    event OrderPlaced(address indexed buyer, uint256 indexed orderId);
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

    function getPriceOfItem(uint256 item) public view returns (uint256) {
        return itemPrices[item] * skillOracle.currentPrice() / 100;
    }

    function getPriceOfBasket(uint256[] memory items, uint8[] memory amounts) public view returns (uint256) {
        require(items.length == amounts.length, "Basket mismatch");
        uint256 sumCents = 0;
        for(uint i = 0; i < items.length; i++) {
            require(itemPrices[items[i]] > 0 && amounts[i] > 0, "Invalid item");
            sumCents = sumCents.add(itemPrices[items[i]].mul(amounts[i]));
        }
        return sumCents.mul(skillOracle.currentPrice()) / 100;
    }

    function getOrder(uint256 orderId) public view
        returns(
            address buyer,
            uint32[] memory basketItems,
            uint32[] memory basketAmounts,
            uint256 paidAmount,
            uint256 timestamp,
            uint8 status
        )
    {
        buyer = orderBuyer[orderId];

        uint256 basketSize = getBasketSize(orderId);
        basketItems = new uint32[](basketSize);
        basketAmounts = new uint32[](basketSize);
        for(uint i = 0; i < basketSize; i++) {
            basketItems[i] = getBasketItem(orderId, i);
            basketAmounts[i] = getBasketItemAmount(orderId, i);
        }
        
        paidAmount = orderPaidAmount[orderId];
        timestamp = getOrderTimestamp(orderId);
        status = getOrderStatus(orderId);
    }
    
    function getBasketSize(uint256 orderId) public view returns(uint256) {
        return orderBaskets[orderId].length;
    }

    function getBasketItem(uint256 orderId, uint256 basketItemIndex) public view returns(uint32) {
        return (orderBaskets[orderId][basketItemIndex] & 0xffffff00) >> 8;
    }
    
    function getBasketItemAmount(uint256 orderId, uint256 basketItemIndex) public view returns(uint32) {
        return orderBaskets[orderId][basketItemIndex] & 0xff;
    }

    function getOrderTimestamp(uint256 orderId) public view returns (uint256) {
        return orderData[orderId] >> 8;
    }

    function getOrderStatus(uint256 orderId) public view returns (uint8) {
        return uint8(orderData[orderId] & 0xff);
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

    function setItemPrices(uint256[] calldata items, uint256[] calldata usdCents) external restricted {
        for(uint i = 0; i < items.length; i++)
            itemPrices[items[i]] = usdCents[i];
    }

    function setItemsToPrice(uint256[] calldata items, uint256 usdCents) external restricted {
        for(uint i = 0; i < items.length; i++)
            itemPrices[items[i]] = usdCents;
    }

    function placeOrder(uint256[] calldata items, uint8[] calldata amounts) external returns (uint256) {
        require(vars[VAR_ORDERS_ENABLED] != 0
            || hasRole(GAME_ADMIN,msg.sender),
            "Cannot place orders right now");

        uint256 payingAmount = getPriceOfBasket(items,amounts);

        game.payContractTokenOnly(msg.sender, payingAmount, vars[VAR_TRACK_INCOME] != 0);
            
        orderBuyer[nextOrderID] = msg.sender;
        orderData[nextOrderID] = now << 8; // lowest 8 bits is status (default 0)

        for(uint i = 0; i < items.length; i++) {
            orderBaskets[nextOrderID].push(amounts[i] | (uint32(items[i]) << 8));
        }
        orderPaidAmount[nextOrderID] = payingAmount;

        emit OrderPlaced(msg.sender, nextOrderID);
        return nextOrderID++;
    }

    function setOrderStatus(uint256 orderId, uint8 status) external restricted {
        _setOrderStatus(orderId, status);
    }

    function _setOrderStatus(uint256 orderId, uint8 status) internal {
        orderData[orderId] = ((orderData[orderId] >> 8) << 8) | status;
        emit OrderStatusChanged(orderId, status);
    }

    function setOrderStatuses(uint256[] calldata orderIds, uint8[] calldata statuses) external restricted {
        for(uint i = 0; i < orderIds.length; i++)
            _setOrderStatus(orderIds[i], statuses[i]);
    }

    function setOrdersToStatus(uint256[] calldata orderIds, uint8 status) external restricted {
        for(uint i = 0; i < orderIds.length; i++)
            _setOrderStatus(orderIds[i], status);
    }

    function processOrders(uint256[] calldata orderIds, uint256 _lowestUnprocessedOrderID) external restricted {
        for(uint i = 0; i < orderIds.length; i++)
            _setOrderStatus(orderIds[i], STATUS_PROCESSED);
        lowestUnprocessedOrderID = _lowestUnprocessedOrderID;
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
