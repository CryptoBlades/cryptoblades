pragma solidity ^0.6.2;

import "./staking/StakingRewardsUpgradeable.sol";
import "./interfaces/IStakeFromGame.sol";
import "./cryptoblades.sol";

contract SkillStakingRewardsUpgradeable is
    IStakeFromGame,
    StakingRewardsUpgradeable
{

    SpecialWeaponsManager private specialWeaponsManager;

    /* ========== VIEWS ========== */

    function game() external view returns (CryptoBlades) {
        return __game;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function migrateTo_23b3a8b(CryptoBlades _game) external onlyOwner {
        __game = _game;
    }

    function migrateTo_e1fe97c(SpecialWeaponsManager _swm) external onlyOwner {
        specialWeaponsManager = _swm;
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
        stakingToken.safeTransferFrom(address(__game), address(this), amount);
    }

    function unstakeToGame(address player, uint256 amount)
        external
        override
        normalMode
        nonReentrant
        whenNotPaused
        onlyGame
        updateReward(player)
    {
        _unstake(player, amount);
        stakingToken.transfer(address(__game), amount);
    }

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
        specialWeaponsManager.updateStakingReward(msg.sender, _balances[msg.sender]);
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
        specialWeaponsManager.updateStakingReward(msg.sender, _balances[msg.sender]);
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
            specialWeaponsManager.updateStakingReward(msg.sender, _balances[msg.sender]);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGame() {
        require(msg.sender == address(__game), "Only callable by game");
        _;
    }
}
