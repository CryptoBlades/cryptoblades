// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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
    //using SafeMath for uint256;
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
            rewardPerTokenStored +
            (lastTimeRewardApplicable() -
                ((lastUpdateTime) * (rewardRate) * (1e18)) /
                (_totalSupply));
    }

    function earned(address account) public view override returns (uint256) {
        return
            (_balances[account] *
                (rewardPerToken() - (userRewardPerTokenPaid[account]))) /
            (1e18) +
            (rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate * (rewardsDuration);
    }

    //TODO: Check this logic, I had to re-write it in the SafeMath removal.
    function getStakeRewardDistributionTimeLeft()
        external
        view
        override
        returns (uint256)
    {
        //(bool success, uint256 diff) = periodFinish.trySub(block.timestamp);
        uint256 time = periodFinish - block.timestamp;
        if( time < 0){
            return 0;
        }
        
        return time;
    }

    function getStakeUnlockTimeLeft() external view override returns (uint256) {
        uint256 time = _stakeTimestamp[msg.sender] + ((minimumStakeTime) - (block.timestamp));
            
            if(time > 0){
                return time;
            }
           return 0; 
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
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply + (amount);
        _balances[msg.sender] = _balances[msg.sender] + (amount);
        if (_stakeTimestamp[msg.sender] == 0) {
            _stakeTimestamp[msg.sender] = block.timestamp;
        }
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
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
                block.timestamp - (_stakeTimestamp[msg.sender]) >=
                minimumStakeTime,
            "Cannot withdraw until minimum staking time has passed"
        );
        _totalSupply = _totalSupply - (amount);
        _balances[msg.sender] = _balances[msg.sender] - (amount);
        if (_balances[msg.sender] == 0) {
            _stakeTimestamp[msg.sender] = 0;
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
                block.timestamp - (_stakeTimestamp[msg.sender]) >=
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
            _totalSupply = _totalSupply - (amount);
            _balances[msg.sender] = _balances[msg.sender] - (amount);
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
            rewardRate = reward / (rewardsDuration);
        } else {
            uint256 remaining = periodFinish - (block.timestamp);
            uint256 leftover = remaining * (rewardRate);
            rewardRate = reward + (leftover) / (rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance / (rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + (rewardsDuration);
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

    function enableFailsafeMode() public override normalMode onlyOwner {
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
            stakingToken.balanceOf(address(this)) - (_totalSupply);

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

    // event RewardAdded(uint256 reward);
    // event Staked(address indexed user, uint256 amount);
    // event Withdrawn(address indexed user, uint256 amount);
    // event RewardPaid(address indexed user, uint256 reward);
    // event RewardsDurationUpdated(uint256 newDuration);
    // event MinimumStakeTimeUpdated(uint256 newMinimumStakeTime);
    event Recovered(address token, uint256 amount);
}
