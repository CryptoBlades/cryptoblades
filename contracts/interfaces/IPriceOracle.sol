pragma solidity ^0.6.5;

import "./IPriceListener.sol";

interface IPriceOracle {
    // Views
    function currentPrice() external view returns (uint256 price);

    // Mutative
    function registerListener(IPriceListener listener) external;
    function setCurrentPrice(uint256 price) external;

    // Events
    event CurrentPriceUpdated(uint256 price);
}
