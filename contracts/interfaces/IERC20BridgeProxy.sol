pragma solidity ^0.6.5;

interface IERC20BridgeProxy {
    function isEnabled() external view returns (bool);

    function sigVersion() external view returns (uint256);

    function canBridge(address wallet, uint256 amount, uint256 targetChain) external view returns (bool);
}