pragma solidity ^0.6.0;

interface IERC20MintAccess {

    // Mutative
    function mintAccess(address receiver, uint256 ref, uint256 amount) external;

    // Events
    event MintAccess(address indexed minter, address indexed receiver, uint256 indexed ref, uint256 amount);
}
