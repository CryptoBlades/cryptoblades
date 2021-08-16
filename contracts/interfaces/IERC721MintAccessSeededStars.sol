pragma solidity ^0.6.0;

interface IERC721MintAccessSeededStars {

    // Mutative
    function mintAccessSeededStars(address receiver, uint256 ref, uint256 seed, uint8 stars) external returns(uint256);

}
