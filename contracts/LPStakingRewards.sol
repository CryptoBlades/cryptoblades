// SPDX-License-Identifier: MIT

import "./staking/StakingRewards.sol";

contract LPStakingRewards is StakingRewards {
    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _minimumStakeTime
    )
        public
        StakingRewards(
            _owner,
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken,
            _minimumStakeTime
        )
    {}
}
