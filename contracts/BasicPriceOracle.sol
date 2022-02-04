pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IPriceListener.sol";

contract BasicPriceOracle is IPriceOracle, Initializable, AccessControlUpgradeable {
    bytes32 public constant PRICE_UPDATER = keccak256("PRICE_UPDATER");
    bytes32 public constant REGISTER_LISTENER = keccak256("REGISTER_LISTENER");

    bool private priceSet;
    uint256 private currentPrice_;
    IPriceListener[] private listeners;

    function initialize() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PRICE_UPDATER, _msgSender());

        priceSet = false;
        currentPrice_ = 0;
    }

    // TODO: Add migration
    //      _setupRole(REGISTER_LISTENER, ...);

    // Views
    function currentPrice() external override view returns (uint256) {
        require(priceSet, "Price must be set beforehand");
        return currentPrice_;
    }

    // Mutative
    function registerListener(IPriceListener listener) external override {
        require(hasRole(REGISTER_LISTENER, _msgSender()), "Missing REGISTER_LISTENER role");
        require(address(listener) != address(0));
        listeners.push(listener);
        // This serves both set initial price and to validate the listener.
        listener.speakCurrentPrice(currentPrice_);
    }

    function setCurrentPrice(uint256 _currentPrice) external override {
        require(hasRole(PRICE_UPDATER, _msgSender()), "Missing PRICE_UPDATER role");
        require(_currentPrice > 0, "Price must be non-zero");

        priceSet = true;
        currentPrice_ = _currentPrice;

        emit CurrentPriceUpdated(_currentPrice);

        for(uint i = 0; i < listeners.length; i++) {
            listeners[i].speakCurrentPrice(currentPrice_);
        }
    }

    // Events
    event CurrentPriceUpdated(uint256 currentPrice);
}
