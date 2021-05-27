pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IPriceOracle.sol";

contract BasicPriceOracle is IPriceOracle, Initializable, AccessControlUpgradeable {
    bytes32 public constant PRICE_UPDATER = keccak256("PRICE_UPDATER");

    bool private priceSet;
    uint256 private currentPrice_;

    function initialize() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PRICE_UPDATER, _msgSender());

        priceSet = false;
        currentPrice_ = 0;
    }

    // Views
    function currentPrice() external override view returns (uint256) {
        require(priceSet, "Price must be set beforehand");
        return currentPrice_;
    }

    // Mutative
    function setCurrentPrice(uint256 _currentPrice) external override {
        require(hasRole(PRICE_UPDATER, _msgSender()), "Missing PRICE_UPDATER role");
        require(_currentPrice > 0, "Price must be non-zero");

        priceSet = true;
        currentPrice_ = _currentPrice;

        emit CurrentPriceUpdated(_currentPrice);
    }

    // Events
    event CurrentPriceUpdated(uint256 currentPrice);
}
