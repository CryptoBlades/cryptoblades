pragma solidity ^0.6.2;

import "./staking/NftStakingRewardsUpgradeable.sol";
import "./CBKLand.sol";

contract CBKLandT3StakingRewardsUpgradeable is NftStakingRewardsUpgradeable {
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
      stakeTier = 3;
    }
    
    function stake(uint256 id) public virtual override {
      uint256 landTier = __cbkLand.getLandTier(id);
      require(landTier == stakeTier, 'Land tier mismatch');
      super.stake(id);
    }
}