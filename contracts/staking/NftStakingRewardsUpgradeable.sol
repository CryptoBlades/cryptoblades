pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

// Inheritance
import "./interfaces/INftStakingRewards.sol";
import "./RewardsDistributionRecipientUpgradeable.sol";
import "./FailsafeUpgradeable.sol";
import "../CBKLand.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract NftStakingRewardsUpgradeable is
    INftStakingRewards,
    IERC721ReceiverUpgradeable,
    Initializable,
    RewardsDistributionRecipientUpgradeable,
    ReentrancyGuardUpgradeable,
    FailsafeUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC721 public stakingToken;
    uint256 public periodFinish;
    uint256 public override rewardRate;
    uint256 public override rewardsDuration;
    uint256 public override minimumStakeAmount;
    uint256 public override minimumStakeTime;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => EnumerableSet.UintSet) private _userStakedNfts;
    mapping(uint256 => address) private _stakedNftOwner;
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

        transferOwnership(_owner);

        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC721(_stakingToken);
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

    function stakedIdsOf(address account)
        external
        view
        override
        returns (uint256[] memory stakedIds)
    {
        uint256 amount = _userStakedNfts[account].length();
        stakedIds = new uint256[](amount);

        EnumerableSet.UintSet storage stakedNfts = _userStakedNfts[account];

        for (uint256 i = 0; i < stakedNfts.length(); i++) {
            uint256 id = stakedNfts.at(i);
            stakedIds[i] = id;
        }
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
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view override returns (uint256) {
        return
            _userStakedNfts[account].length()
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getStakeRewardDistributionTimeLeft()
        external
        view
        override
        returns (uint256)
    {
        (bool success, uint256 diff) = periodFinish.trySub(block.timestamp);
        return success ? diff : 0;
    }

    function getStakeUnlockTimeLeft() external view override returns (uint256) {
        (bool success, uint256 diff) = _stakeTimestamp[msg.sender]
            .add(minimumStakeTime)
            .trySub(block.timestamp);
        return success ? diff : 0;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _userStakedNfts[account].length();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 id)
        public
        virtual
        override
        normalMode
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        _totalSupply = _totalSupply.add(1);
        _userStakedNfts[msg.sender].add(id);
        _stakedNftOwner[id] = msg.sender;
        if (_stakeTimestamp[msg.sender] == 0) {
            _stakeTimestamp[msg.sender] = block.timestamp;
        }
        stakingToken.safeTransferFrom(msg.sender, address(this), id);
        emit Staked(msg.sender, id);
    }

    function withdraw(uint256 id)
        public
        override
        normalMode
        nonReentrant
        isOwner(id)
        updateReward(msg.sender)
    {
        require(
            minimumStakeTime == 0 ||
                block.timestamp.sub(_stakeTimestamp[msg.sender]) >=
                minimumStakeTime,
            "Cannot withdraw until minimum staking time has passed"
        );
        _totalSupply = _totalSupply.sub(1);
        _userStakedNfts[msg.sender].remove(id);
        delete _stakedNftOwner[id];
        if (_userStakedNfts[msg.sender].length() == 0) {
            _stakeTimestamp[msg.sender] = 0;
        }
        stakingToken.safeTransferFrom(address(this), msg.sender, id);
        emit Withdrawn(msg.sender, id);
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
        require(
            minimumStakeTime == 0 ||
                block.timestamp.sub(_stakeTimestamp[msg.sender]) >=
                minimumStakeTime,
            "Cannot withdraw until minimum staking time has passed"
        );

        uint256 amount = _userStakedNfts[msg.sender].length();
        _totalSupply = _totalSupply.sub(amount);
        EnumerableSet.UintSet storage stakedNfts = _userStakedNfts[msg.sender];

        for (uint256 i = 0; i < stakedNfts.length(); i++) {
            uint256 id = stakedNfts.at(i);
            stakedNfts.remove(id);
            delete _stakedNftOwner[id];
            stakingToken.safeTransferFrom(address(this), msg.sender, id);
        }

        if (_userStakedNfts[msg.sender].length() == 0) {
            _stakeTimestamp[msg.sender] = 0;
        }

        getReward();
    }

    function recoverOwnStake() external failsafeMode {
        uint256 amount = _userStakedNfts[msg.sender].length();
        _totalSupply = _totalSupply.sub(amount);
        EnumerableSet.UintSet storage stakedNfts = _userStakedNfts[msg.sender];

        for (uint256 i = 0; i < stakedNfts.length(); i++) {
            uint256 id = stakedNfts.at(i);
            stakedNfts.remove(id);
            delete _stakedNftOwner[id];
            stakingToken.safeTransferFrom(address(this), msg.sender, id);
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

    function setMinimumStakeAmount(uint256 _minimumStakeAmount)
        external
        normalMode
        onlyOwner
    {
        minimumStakeAmount = _minimumStakeAmount;
        emit MinimumStakeAmountUpdated(_minimumStakeAmount);
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
        minimumStakeAmount = 0;
        minimumStakeTime = 0;
        periodFinish = 0;
        rewardRate = 0;
        rewardPerTokenStored = 0;

        super.enableFailsafeMode();
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

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event MinimumStakeAmountUpdated(uint256 newMinimumStakeAmount);
    event MinimumStakeTimeUpdated(uint256 newMinimumStakeTime);
    event Recovered(address token, uint256 amount);

    /* ========== MODIFIERS ========== */
    modifier isOwner(uint256 id) {
        require(_stakedNftOwner[id] == msg.sender, "Access denied");
        _;
    }

    // something
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 _id,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        // NOTE: The contract address is always the message sender.
        address _tokenAddress = msg.sender;

        require(
            address(stakingToken) ==_tokenAddress &&
                _stakedNftOwner[_id] != address(0),
            "Token ID not listed"
        );

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}
