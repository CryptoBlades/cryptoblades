pragma solidity ^0.6.2;

import "./staking/StakingRewardsUpgradeable.sol";

contract LP2StakingRewardsUpgradeable is StakingRewardsUpgradeable {
   function recoverERC20(address tokenAddress, uint256 tokenAmount)
      external
      override
      onlyOwner
  {
      IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
      emit Recovered(tokenAddress, tokenAmount);
  }
}
