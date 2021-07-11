pragma solidity ^0.6.2;

import "./staking/StakingRewardsUpgradeable.sol";
import "./interfaces/IStakeFromGame.sol";
import "./cryptoblades.sol";

contract SkillStakingRewardsUpgradeable is IStakeFromGame, StakingRewardsUpgradeable {
    /* ========== STATE VARIABLES ========== */

    CryptoBlades public game;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function migrateTo_23b3a8b(CryptoBlades _game) external onlyOwner {
        game = _game;
    }

    function stakeFromGame(address player, uint256 amount)
        external
        override
        normalMode
        nonReentrant
        whenNotPaused
        onlyGame
        updateReward(player)
    {
        _stake(player, amount);
        stakingToken.safeTransferFrom(address(game), address(this), amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGame() {
        require(msg.sender == address(game), "Only callable by game");
        _;
    }
}
