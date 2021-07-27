pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../cryptoblades.sol";

// Inheritance
import "./interfaces/IStakingRewards.sol";
import "./RewardsDistributionRecipientUpgradeable.sol";
import "./FailsafeUpgradeable.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewardsUpgradeable is
    IStakingRewards,
    Initializable,
    RewardsDistributionRecipientUpgradeable,
    ReentrancyGuardUpgradeable,
    FailsafeUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish;
    uint256 public override rewardRate;
    uint256 public override rewardsDuration;
    uint256 public override minimumStakeTime;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _stakeTimestamp;

    // used only by the SKILL-for-SKILL staking contract
    CryptoBlades internal __game;

    uint256 public override minimumStakeAmount;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _minimumStakeTime
    ) public virtual initializer {
        __Context_init();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __Failsafe_init_unchained();
        __ReentrancyGuard_init_unchained();
        __RewardsDistributionRecipient_init_unchained();

        // for consistency with the old contract
        transferOwnership(_owner);

        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        minimumStakeTime = _minimumStakeTime;

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = 180 days;
    }

    function migrateTo_8cb6e70(uint256 _minimumStakeAmount) external onlyOwner {
        minimumStakeAmount = _minimumStakeAmount;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view override returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getStakeRewardDistributionTimeLeft()
        external
        override
        view
        returns (uint256)
    {
        (bool success, uint256 diff) = periodFinish.trySub(block.timestamp);
        return success ? diff : 0;
    }

    function getStakeUnlockTimeLeft() external override view returns (uint256) {
        (bool success, uint256 diff) =
            _stakeTimestamp[msg.sender].add(minimumStakeTime).trySub(
                block.timestamp
            );
        return success ? diff : 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

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
        require(amount > 0, "Cannot withdraw 0");
        require(
            minimumStakeTime == 0 ||
                block.timestamp.sub(_stakeTimestamp[msg.sender]) >=
                minimumStakeTime,
            "Cannot withdraw until minimum staking time has passed"
        );
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        if (_balances[msg.sender] == 0) {
            _stakeTimestamp[msg.sender] = 0;
        } else {
            _stakeTimestamp[msg.sender] = block.timestamp;
        }
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward()
        public
        override
        normalMode
        nonReentrant
        updateReward(msg.sender)
    {
        require(
            minimumStakeTime == 0 ||
                block.timestamp.sub(_stakeTimestamp[msg.sender]) >=
                minimumStakeTime,
            "Cannot get reward until minimum staking time has passed"
        );
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external override normalMode {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function recoverOwnStake() external failsafeMode {
        uint256 amount = _balances[msg.sender];
        if (amount > 0) {
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            stakingToken.safeTransfer(msg.sender, amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        override
        normalMode
        onlyRewardsDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // End rewards emission earlier
    function updatePeriodFinish(uint256 timestamp)
        external
        normalMode
        onlyOwner
        updateReward(address(0))
    {
        require(
            timestamp > lastUpdateTime,
            "Timestamp must be after lastUpdateTime"
        );
        periodFinish = timestamp;
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken),
            "Cannot withdraw the staking token"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration)
        external
        normalMode
        onlyOwner
    {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setMinimumStakeTime(uint256 _minimumStakeTime)
        external
        normalMode
        onlyOwner
    {
        minimumStakeTime = _minimumStakeTime;
        emit MinimumStakeTimeUpdated(_minimumStakeTime);
    }

    function setMinimumStakeAmount(uint256 _minimumStakeAmount)
        external
        normalMode
        onlyOwner
    {
        minimumStakeAmount = _minimumStakeAmount;
        emit MinimumStakeAmountUpdated(_minimumStakeAmount);
    }

    function enableFailsafeMode() public override normalMode onlyOwner {
        minimumStakeAmount = 0;
        minimumStakeTime = 0;
        periodFinish = 0;
        rewardRate = 0;
        rewardPerTokenStored = 0;

        super.enableFailsafeMode();
    }

    function recoverExtraStakingTokensToOwner() external onlyOwner {
        // stake() and withdraw() should guarantee that
        // _totalSupply <= stakingToken.balanceOf(this)
        uint256 stakingTokenAmountBelongingToOwner =
            stakingToken.balanceOf(address(this)).sub(_totalSupply);

        if (stakingTokenAmountBelongingToOwner > 0) {
            stakingToken.safeTransfer(
                owner(),
                stakingTokenAmountBelongingToOwner
            );
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _stake(address staker, uint256 amount) internal
    {
        require(amount >= minimumStakeAmount, "Minimum stake amount required");
        _totalSupply = _totalSupply.add(amount);
        _balances[staker] = _balances[staker].add(amount);
        if (_stakeTimestamp[staker] == 0) {
            _stakeTimestamp[staker] = block.timestamp;
        }
        emit Staked(staker, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        if (!failsafeModeActive) {
            rewardPerTokenStored = rewardPerToken();
            lastUpdateTime = lastTimeRewardApplicable();
            if (account != address(0)) {
                rewards[account] = earned(account);
                userRewardPerTokenPaid[account] = rewardPerTokenStored;
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event MinimumStakeTimeUpdated(uint256 newMinimumStakeTime);
    event MinimumStakeAmountUpdated(uint256 newMinimumStakeAmount);
    event Recovered(address token, uint256 amount);
}
