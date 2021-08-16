pragma solidity ^0.6.0;

interface IERC721MintAccessSeeded {

    // Mutative
    function mintAccessSeeded(address receiver, uint256 ref, uint256 seed) external returns(uint256);

}
