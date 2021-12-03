pragma solidity ^0.6.2;

import "./staking/StakingRewardsUpgradeable.sol";

contract KingStakingRewardsUpgradeable is StakingRewardsUpgradeable {
  function withdrawWithoutFee(uint256 amount) public {
      super.withdraw(amount);
      uint256 feeCompensation = amount.mul(1e16).div(1e18);
      stakingToken.safeTransfer(msg.sender, feeCompensation);
  }

  function getRewardWithoutFee() public {
    uint256 feeCompensation = rewards[msg.sender].mul(1e16).div(1e18);
    super.getReward();
    if(feeCompensation > 0) {
      rewardsToken.safeTransfer(msg.sender, feeCompensation);
    }
  }
}