pragma solidity ^0.6.5;

interface IPriceListener {
    function speakCurrentPrice(uint256 price) external;
}
