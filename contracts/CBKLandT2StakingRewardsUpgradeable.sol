pragma solidity ^0.6.2;

import "./staking/NftStakingRewardsUpgradeable.sol";
import "./CBKLand.sol";

contract CBKLandT2StakingRewardsUpgradeable is NftStakingRewardsUpgradeable {
    CBKLand internal __cbkLand;
    uint256 public stakeTier;

    function initialize(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _minimumStakeTime,
        CBKLand _cbkLand
    ) public initializer {
      super.initialize(
        _owner,
        _rewardsDistribution,
        _rewardsToken,
        _stakingToken,
        _minimumStakeTime);
      __cbkLand = _cbkLand;
      stakeTier = 2;
    }

    function stake(uint256 id) public virtual override {
      uint256 landTier = __cbkLand.getLandTier(id);
      require(landTier == stakeTier, 'Land tier mismatch');
      super.stake(id);
    }

    function bulkStake(uint256[] memory ids) public virtual override {
        for(uint i = 0; i < ids.length; i++) {
            uint256 landTier = __cbkLand.getLandTier(ids[i]);
            require(landTier == stakeTier, 'Land tier mismatch');
        }
        super.bulkStake(ids);
    }
}