pragma solidity ^0.6.0;

interface IERC20MintAccess {

    // Mutative
    function mintAccess(address receiver, uint256 ref, uint256 amount) external returns(uint256);

}
