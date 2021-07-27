pragma solidity ^0.6.0;

interface IERC721MintAccessSeeded {

    // Mutative
    function mintAccessSeeded(address receiver, uint256 ref, uint256 seed) external;

    // Events
    event MintAccessSeeded(address indexed minter, address indexed receiver, uint256 ref, uint256 indexed id);
}
