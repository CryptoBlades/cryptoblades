pragma solidity ^0.6.2;

import "./staking/StakingRewardsUpgradeable.sol";
import "./interfaces/IStakeFromGame.sol";
import "./cryptoblades.sol";

contract ValorStakingRewardsUpgradeable is
    StakingRewardsUpgradeable
{

    function stake(uint256 amount)
        external
        override
        normalMode
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        _stake(msg.sender, amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount)
        public
        override
        normalMode
        nonReentrant
        updateReward(msg.sender)
    {
        require(
            minimumStakeTime == 0 ||
                block.timestamp.sub(_stakeTimestamp[msg.sender]) >=
                minimumStakeTime ||
                periodFinish <= block.timestamp,
            "Cannot withdraw until minimum staking time has passed"
        );
        _unstake(msg.sender, amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }

    function exit() external override normalMode {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function recoverOwnStake() external override failsafeMode {
        uint256 amount = _balances[msg.sender];
        if (amount > 0) {
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            stakingToken.safeTransfer(msg.sender, amount);
        }
    }
}
