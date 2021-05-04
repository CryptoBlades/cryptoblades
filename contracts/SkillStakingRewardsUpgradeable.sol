pragma solidity ^0.6.2;

import "./staking/StakingRewardsUpgradeable.sol";

contract SkillStakingRewardsUpgradeable is StakingRewardsUpgradeable {
    function initialize(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _minimumStakeTime
    ) public override initializer {
        StakingRewardsUpgradeable.initialize(
            _owner,
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken,
            _minimumStakeTime
        );
    }
}
