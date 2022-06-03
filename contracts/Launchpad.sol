pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./common.sol";
import "./cryptoblades.sol";

contract Launchpad is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    struct Launch {
        string name;
        string tokenSymbol;
        string detailsJsonUri;
        string imageUrl;
        address fundingTokenAddress;
        uint256 phase;
        bool commitOnly;
    }

    // VARS
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_TIERS_AMOUNT = 1;
    uint256 public constant VAR_FUNDING_PERIOD_PHASE_1 = 2;
    uint256 public constant VAR_FUNDING_PERIOD_PHASE_2 = 3;
    uint256 public constant VAR_UNCLAIMED_TO_ALLOCATION_MULTIPLIER = 4;
    uint256 public constant VAR_UNCLAIMED_ALLOCATION_PERCENTAGE = 5;
    uint256 public constant VAR_UNCLAIMED_COMMIT_WINDOW = 6;
    uint256 public constant VAR_UNCLAIMED_COMMIT_START_OFFSET = 7;
    

    // TIERS INFO
    mapping(uint256 => uint256) public tierStakingRequirement;
    mapping(uint256 => uint256) public tierAllocationWeight;

    // LAUNCHPAD PROJECT INFO
    mapping(uint256 => Launch) public launches;
    mapping(uint256 => uint256) public launchTokenPrice;
    mapping(uint256 => uint256) public launchStartTime;
    mapping(uint256 => uint256) public launchFundsToRaise;
    mapping(uint256 => uint256) public launchBaseAllocation;
    mapping(uint256 => uint256) public launchTotalRaised;
    mapping(uint256 => address) public launchTokenAddress;

    // USER INFO
    mapping(uint256 => EnumerableSet.AddressSet) launchEligibleUsersSnapshot;
    mapping(uint256 => mapping(address => uint256)) public launchUserStakedAmountSnapshot;    
    mapping(uint256 => mapping(address => uint256)) public launchUserInvestment;
    mapping(uint256 => mapping(address => uint256)) public launchUserUnclaimedSkillCommittedValue;
    mapping(uint256 => uint256) public launchTotalUnclaimedSkillCommittedValue;
    mapping(uint256 => mapping(address => uint256)) public launchUserTotalUnclaimedSkillCommittedValue;

    // VESTING INFO
    mapping(uint256 => uint256[]) launchPeriodicVestingsPercentages;
    mapping(uint256 => mapping(uint256 => uint256)) public launchPeriodicVestingsStartTimestamps;
    mapping(uint256 => uint256) public launchLinearVestingsDurations;
    mapping(uint256 => uint256) public launchLinearVestingsStartTimestamps;
    mapping(address => mapping(uint256 => uint256)) public userLinearVestingClaimTimestamp;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public userClaimedVestingPortion;

    uint256 public nextLaunchId;
    uint256 public skillPrice;

    CryptoBlades _game;

    function initialize(CryptoBlades game) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        _game = game;
        nextLaunchId = 1;
    }

    event LaunchAdded(uint256 indexed launchId, uint256 phase);
    event Invested(address indexed user, uint256 amount);
    event SkillCommitted(address indexed user, address indexed targetWallet, uint256 indexed launchId, uint256 amount);
    event PeriodicVestingClaimed(address indexed user, uint256 indexed launchId, uint256 indexed vestingId, uint256 amount);
    event LinearVestingClaimed(address indexed user, uint256 indexed launchId, uint256 amount);
    event FundsWithdrawn(uint256 indexed launchId, uint256 amount);
    event PeriodicVestingEnabled(uint256 indexed launchId, uint256 indexed vestingId, uint256 timestamp);
    event LinearVestingEnabled(uint256 indexed launchId, uint256 timestamp);

    // MODIFIERS
    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier onlyPhase1(uint256 launchId) {
        _onlyPhase1(launchId);
        _;
    }

    function _onlyPhase1(uint256 launchId) internal pure {
        require(launchId % 2 == 1, "Usable only on phase 1");
    }

    modifier isUserWhitelistedForLaunch(address user, uint256 launchId) {
        _isUserWhitelistedForLaunch(user, launchId);
        _;
    }

    function _isUserWhitelistedForLaunch(address user, uint256 launchId) internal view {
        require(isUserWhitelisted(user, launchId), "Not whitelisted");
    }

    modifier isTokenAddressSet(uint256 launchId) {
        _isTokenAddressSet(launchId);
        _;
    }

    function _isTokenAddressSet(uint256 launchId) internal view {
        require(launchTokenAddress[launchId] != address(0), "Token address not set");
    }

    modifier launchNotStarted(uint256 launchId) {
        _launchNotStarted(launchId);
        _;
    }

    function _launchNotStarted(uint256 launchId) internal view {
        require(launchStartTime[launchId] == 0 || launchStartTime[launchId] > block.timestamp, "Launch started");
    }

    // VIEWS

    function getTierForStakedAmount(uint256 amount) public view returns (uint256 tier) {
        for (uint256 i = 1; i <= vars[VAR_TIERS_AMOUNT]; i++) {
            if (amount >= tierStakingRequirement[i]) {
                tier++;
            } else {
                break;
            }
        }
    }

    function getLaunchAllocationForTier(uint256 launchId, uint256 tier) public view returns (uint256) {
        return launchBaseAllocation[launchId].mul(tierAllocationWeight[tier]);
    }

    function getUserRemainingAllocationForLaunch(address user, uint256 launchId) public view returns (uint256 maxAllocation) {
        if(launchId % 2 == 0) {
            maxAllocation = getLaunchAllocationForTier(launchId, getTierForStakedAmount(launchUserStakedAmountSnapshot[launchId.sub(1)][user]));
        }
        else {
            maxAllocation = getLaunchAllocationForTier(launchId, getTierForStakedAmount(launchUserStakedAmountSnapshot[launchId][user]));
        }
        maxAllocation += launchUserTotalUnclaimedSkillCommittedValue[launchId][user].mul(vars[VAR_UNCLAIMED_TO_ALLOCATION_MULTIPLIER]);
        maxAllocation = maxAllocation.sub(launchUserInvestment[launchId][user]);
    }

    function getAvailableClaimAmount(uint256 launchId, uint256 vestingId) public onlyPhase1(launchId) view returns (uint256 claimAmount) {
        uint256 decimals = ERC20(launchTokenAddress[launchId]).decimals();
        uint256 totalUserInvestment = launchUserInvestment[launchId][msg.sender].add(launchUserInvestment[launchId + 1][msg.sender]);
        claimAmount = totalUserInvestment.mul(1e18).div(launchTokenPrice[launchId]).mul(launchPeriodicVestingsPercentages[launchId][vestingId]).div(100);
        claimAmount = Common.adjustDecimals(claimAmount, decimals);
    }

    function getLinearClaimAmount(uint256 launchId) public onlyPhase1(launchId) view returns (uint256 claimAmount) {
        uint256 decimals = ERC20(launchTokenAddress[launchId]).decimals();
        uint256 totalUserInvestment = launchUserInvestment[launchId][msg.sender].add(launchUserInvestment[launchId + 1][msg.sender]);
        uint256 lastClaimTimestamp = userLinearVestingClaimTimestamp[msg.sender][launchId];
        if(lastClaimTimestamp == 0) {
            lastClaimTimestamp = launchLinearVestingsStartTimestamps[launchId];
        }
        uint256 effectiveClaimTimestamp = launchLinearVestingsStartTimestamps[launchId] + launchLinearVestingsDurations[launchId];
        if(block.timestamp < effectiveClaimTimestamp) {
            effectiveClaimTimestamp = block.timestamp;
        }
        
        claimAmount = totalUserInvestment.mul(1e18).div(launchTokenPrice[launchId]).mul(effectiveClaimTimestamp.sub(lastClaimTimestamp)).div(launchLinearVestingsDurations[launchId]);
        claimAmount = Common.adjustDecimals(claimAmount, decimals);
    }

    function getLaunchDetails(uint256 launchId) public view returns (
        uint256 tokenPrice,
        uint256 startTime,
        uint256 fundsToRaise,
        uint256 maxAllocation,
        uint256 totalRaised,
        address tokenAddress) 
    {
        tokenPrice = launchTokenPrice[launchId];
        startTime = launchStartTime[launchId];
        fundsToRaise = launchFundsToRaise[launchId];
        maxAllocation = getOverallMaxAllocation(launchId);
        totalRaised = launchTotalRaised[launchId];
        tokenAddress = launchTokenAddress[launchId];
    }

    function getOverallMaxAllocation(uint256 launchId) public view returns (uint256) {
        return getLaunchAllocationForTier(launchId, vars[VAR_TIERS_AMOUNT]);
    }

    function isUserWhitelisted(address user, uint256 launchId) public view returns (bool) {
        if(launchId % 2 == 0) launchId = launchId.sub(1);
        return launchEligibleUsersSnapshot[launchId].contains(user);
    }

    function getTotalUnlockedPercentage(uint256 launchId) public view returns (uint256 totalUnlockedPercentage) {
        for(uint i = 0; i < launchPeriodicVestingsPercentages[launchId].length; i++) {
            totalUnlockedPercentage += launchPeriodicVestingsPercentages[launchId][i];
        }
    }

    function getLaunchVestingPercentages(uint256 launchId) public view returns(uint256[] memory) {
        return launchPeriodicVestingsPercentages[launchId];
    }

    function getTotalLaunchUserInvestment(uint256 launchId) public onlyPhase1(launchId) view returns(uint256) {
        return launchUserInvestment[launchId][msg.sender].add(launchUserInvestment[launchId + 1][msg.sender]);
    }

    function getUnclaimedCommittedValue(uint256 launchId) public view returns(uint256) {
        return launchTotalUnclaimedSkillCommittedValue[launchId].mul(vars[VAR_UNCLAIMED_TO_ALLOCATION_MULTIPLIER]);
    }

    // RESTRICTED FUNCTIONS

    // TIERS

    function setBrandNewTiers(uint256[] calldata tierIds, uint256[] calldata stakingRequirements, uint256[] calldata tierWeights) external restricted {
        require(tierIds.length == stakingRequirements.length, "Wrong input");
        vars[VAR_TIERS_AMOUNT] = tierIds.length;
        for (uint256 i = 0; i < tierIds.length; i++) {
            require(tierIds[i] > 0 && tierIds[i] <= vars[VAR_TIERS_AMOUNT], "Wrong id");
            tierStakingRequirement[tierIds[i]] = stakingRequirements[i];
            tierAllocationWeight[tierIds[i]] = tierWeights[i];
        }
    }

    function setTiersRequirements(uint256[] calldata tierIds, uint256[] calldata stakingRequirements) external restricted {
        require(tierIds.length <= vars[VAR_TIERS_AMOUNT], "Too many tiers");
        require(tierIds.length == stakingRequirements.length, "Wrong input");
        for (uint256 i = 0; i < tierIds.length; i++) {
            require(tierIds[i] > 0 && tierIds[i] <= vars[VAR_TIERS_AMOUNT], "Wrong id");
            tierStakingRequirement[tierIds[i]] = stakingRequirements[i];
        }
    }

    function setTiersAllocationWeights(uint256[] calldata tierIds, uint256[] calldata tierWeights) external restricted {
        require(tierIds.length <= vars[VAR_TIERS_AMOUNT], "Too many tiers");
        require(tierIds.length == tierWeights.length, "Wrong input");
        for (uint256 i = 0; i < tierIds.length; i++) {
            require(tierIds[i] > 0 && tierIds[i] <= vars[VAR_TIERS_AMOUNT], "Wrong id");
            tierAllocationWeight[tierIds[i]] = tierWeights[i];
        }
    }

    // PROJECT DETAILS

    function addNewLaunch(
        string calldata name,
        string calldata tokenSymbol,
        string calldata detailsJsonUri,
        string calldata imageUrl,
        address fundingTokenAddress,
        bool commitOnly
    ) external restricted {
        launches[nextLaunchId] = Launch(
            name,
            tokenSymbol,
            detailsJsonUri,
            imageUrl,
            fundingTokenAddress,
            1,
            commitOnly
        );

        emit LaunchAdded(nextLaunchId, 1);
        // nextLaunchId + 1 is reserved for Phase 2s
        nextLaunchId += 2;
    }

    function addSecondPhaseForLaunch(uint256 launchId, uint256 startTime) external onlyPhase1(launchId) restricted {
        Launch memory lp = launches[launchId];
        require(launchId < nextLaunchId, "Wrong id");
        require(launchStartTime[launchId + 1] == 0, "Already added");
        require(block.timestamp > launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_1], "Phase 1 not finished");
        require(launchFundsToRaise[launchId].sub(launchTotalRaised[launchId]) > 0, "Tokens sold out");
        launches[launchId + 1] = Launch(
            lp.name,
            lp.tokenSymbol,
            lp.detailsJsonUri,
            lp.imageUrl,
            lp.fundingTokenAddress,
            2,
            lp.commitOnly
        );
        
        launchStartTime[launchId + 1] = startTime;
        launchTokenPrice[launchId + 1] = launchTokenPrice[launchId];
        launchFundsToRaise[launchId + 1] = launchFundsToRaise[launchId].sub(launchTotalRaised[launchId]);
        launchBaseAllocation[launchId + 1] = launchBaseAllocation[launchId];
        launchTokenAddress[launchId + 1] = launchTokenAddress[launchId];
        launchBaseAllocation[launchId + 1] = launchBaseAllocation[launchId];

        emit LaunchAdded(launchId + 1, 2);
    }

    function removeLaunch(uint256 launchId) external restricted {
        delete launches[launchId];
    }

    // UPDATING DETAILS
    function setLaunchDetails(uint256 launchId, uint256 tokenPrice, uint256 startTime, uint256 fundsToRaise) external restricted {
        launchTokenPrice[launchId] = tokenPrice;
        launchStartTime[launchId] = startTime;
        launchFundsToRaise[launchId] = fundsToRaise;
    }

    function updateLaunchName(uint256 launchId, string calldata name) external restricted {
        launches[launchId].name = name;
    }

    function updateLaunchTokenSymbol(uint256 launchId, string calldata tokenSymbol) external restricted {
        launches[launchId].tokenSymbol = tokenSymbol;
    }

    function updateLaunchDetailsJsonUri(uint256 launchId, string calldata detailsJsonUri) external restricted {
        launches[launchId].detailsJsonUri = detailsJsonUri;
    }

    function updateLaunchImageUrl(uint256 launchId, string calldata imageUrl) external restricted {
        launches[launchId].imageUrl = imageUrl;
    }

    function updateLaunchFundingTokenAddress(uint256 launchId, address fundingTokenAddress) external launchNotStarted(launchId) restricted {
        launches[launchId].fundingTokenAddress = fundingTokenAddress;
    }

    function updateLaunchIsCommitOnly(uint256 launchId, bool commitOnly) external launchNotStarted(launchId) restricted {
        launches[launchId].commitOnly = commitOnly;
    }

    function updateLaunchTokenPrice(uint256 launchId, uint256 tokenPrice) external launchNotStarted(launchId) restricted {
        launchTokenPrice[launchId] = tokenPrice;
    }

    function updateLaunchStartTime(uint256 launchId, uint256 startTime) external restricted {
        require(launchTokenPrice[launchId] != 0 && launchFundsToRaise[launchId] != 0, "Set token price and funds to raise first");
        launchStartTime[launchId] = startTime;
    }

    function updateLaunchFundsToRaise(uint256 launchId, uint256 fundsToRaise) external launchNotStarted(launchId) restricted {
        launchFundsToRaise[launchId] = fundsToRaise;
    }

    function updateLaunchTokenAddress(uint256 launchId, address tokenAddress) external onlyPhase1(launchId) restricted {
        launchTokenAddress[launchId] = tokenAddress;
        launchTokenAddress[launchId + 1] = tokenAddress;
    }

    // VESTING

    function enablePeriodicVesting(uint256 launchId, uint256 percentage) external onlyPhase1(launchId) isTokenAddressSet(launchId) restricted {
        require(launchLinearVestingsDurations[launchId] == 0, "Linear vesting enabled");
        require(getTotalUnlockedPercentage(launchId) + percentage <= 100, "Total percentage exceeded");
        uint256 totalLaunchRaised = launchTotalRaised[launchId].add(launchTotalRaised[launchId + 1]);
        uint256 contractBalance = IERC20(launchTokenAddress[launchId]).balanceOf(address(this));
        uint256 decimals = ERC20(launchTokenAddress[launchId]).decimals();
        contractBalance = Common.adjustDecimals(contractBalance, decimals);
        require(contractBalance >=
            totalLaunchRaised.mul(1e18).div(launchTokenPrice[launchId]).mul(getTotalUnlockedPercentage(launchId) + percentage).div(100),
            "Not enough balance");

        launchPeriodicVestingsPercentages[launchId].push(percentage);
        uint256 newVestingId = launchPeriodicVestingsPercentages[launchId].length - 1;
        launchPeriodicVestingsStartTimestamps[launchId][newVestingId] = block.timestamp;
        emit PeriodicVestingEnabled(launchId, newVestingId, block.timestamp);
    }

    function enableLinearVesting(uint256 launchId, uint256 duration) external onlyPhase1(launchId) isTokenAddressSet(launchId) restricted {
        require(duration > 0);
        require(launchPeriodicVestingsPercentages[launchId].length == 0, "Periodic vesting enabled");
        uint256 totalLaunchRaised = launchTotalRaised[launchId].add(launchTotalRaised[launchId + 1]);
        uint256 contractBalance = IERC20(launchTokenAddress[launchId]).balanceOf(address(this));
        uint256 decimals = ERC20(launchTokenAddress[launchId]).decimals();
        contractBalance = Common.adjustDecimals(contractBalance, decimals);
        require(contractBalance >= totalLaunchRaised.mul(1e18).div(launchTokenPrice[launchId]), "Not enough balance");

        launchLinearVestingsDurations[launchId] = duration;
        launchLinearVestingsStartTimestamps[launchId] = block.timestamp;

        emit LinearVestingEnabled(launchId, block.timestamp);
    }

    // WHITELISTING

    function setEligibleUsersData(uint256 launchId, address[] calldata users, uint256[] calldata stakedAmounts) external onlyPhase1(launchId) launchNotStarted(launchId) restricted {
        require(nextLaunchId >= launchId, "Wrong ID");
        require(users.length > 0 && users.length == stakedAmounts.length, "Bad input");

        uint totalWeight = launchBaseAllocation[launchId] == 0 ? 0 : launchFundsToRaise[launchId].div(launchBaseAllocation[launchId]);
        for(uint i = 0; i < users.length; i++) {
            if(!launchEligibleUsersSnapshot[launchId].add(users[i])) continue;
            launchUserStakedAmountSnapshot[launchId][users[i]] = stakedAmounts[i];
            totalWeight += tierAllocationWeight[getTierForStakedAmount(stakedAmounts[i])];
        }
        launchBaseAllocation[launchId] = launchFundsToRaise[launchId].div(totalWeight);
    }

    function setTotalUnclaimedCommitted(uint256 launchId, address[] calldata users, uint256[] calldata totalCommittedValues) external onlyPhase1(launchId) launchNotStarted(launchId) restricted {
        require(nextLaunchId >= launchId, "Wrong ID");
        require(users.length > 0 && users.length == totalCommittedValues.length, "Bad input");
        launchTotalUnclaimedSkillCommittedValue[launchId] = 0;
        for(uint i = 0; i < users.length; i++) {
            launchUserTotalUnclaimedSkillCommittedValue[launchId][users[i]] = totalCommittedValues[i];
            launchTotalUnclaimedSkillCommittedValue[launchId] += totalCommittedValues[i];
        }
        launchBaseAllocation[launchId] = launchBaseAllocation[launchId].sub(launchBaseAllocation[launchId].mul(launchTotalUnclaimedSkillCommittedValue[launchId]).div(launchFundsToRaise[launchId]));
    }

    // WITHDRAW RAISED FUNDS

    function withdrawRaisedFunds(uint256 launchId) external onlyPhase1(launchId) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not owner");
        require(
            block.timestamp > launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_1] &&
            block.timestamp > launchStartTime[launchId + 1] + vars[VAR_FUNDING_PERIOD_PHASE_2],
            "Launch not finished"
        );

        uint256 raisedFunds = launchTotalRaised[launchId].add(launchTotalRaised[launchId + 1]);

        IERC20(launches[launchId].fundingTokenAddress).safeTransfer(msg.sender, raisedFunds);
        emit FundsWithdrawn(launchId, raisedFunds);
    }

    // VARS SETTERS

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for (uint256 i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    function setSkillPrice(uint256 price) external restricted {
        skillPrice = price;
    }

    // USER FUNCTIONS

    function invest(uint256 launchId, uint256 amount) external isUserWhitelistedForLaunch(msg.sender, launchId) {
        Launch memory lp = launches[launchId];
        require(!lp.commitOnly, "Invest on diff chain");
        require(launchStartTime[launchId] != 0 && block.timestamp > launchStartTime[launchId], "Launch not started");
        require((lp.phase == 1 && block.timestamp < launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_1])
            || (lp.phase == 2 && block.timestamp < launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_2]), "Launch ended");
        require(launchTokenPrice[launchId] != 0, "Token price not set");
        require(launchTotalRaised[launchId] + amount <= launchFundsToRaise[launchId], "Amount exceeds remaining supply");
        require(getUserRemainingAllocationForLaunch(msg.sender, launchId) >= amount, "Allocation allowance exceeded");

        IERC20(lp.fundingTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        launchUserInvestment[launchId][msg.sender] += amount;
        launchTotalRaised[launchId] += amount;

        emit Invested(msg.sender, amount);
    }

    function claimPeriodic(uint256 launchId, uint256 vestingId) external {
        require(launchPeriodicVestingsPercentages[launchId].length >= vestingId, "Unavailable");
        require(!userClaimedVestingPortion[msg.sender][launchId][vestingId], "Already claimed");

        userClaimedVestingPortion[msg.sender][launchId][vestingId] = true;
        uint256 claimAmount = getAvailableClaimAmount(launchId, vestingId);
        IERC20(launchTokenAddress[launchId]).safeTransfer(msg.sender, claimAmount);

        emit PeriodicVestingClaimed(msg.sender, launchId, vestingId, claimAmount);
    }

    function claimLinear(uint256 launchId) external {
        require(launchLinearVestingsDurations[launchId] > 0, "Unavailable");

        uint256 claimAmount = getLinearClaimAmount(launchId);
        userLinearVestingClaimTimestamp[msg.sender][launchId] = block.timestamp;
        IERC20(launchTokenAddress[launchId]).safeTransfer(msg.sender, claimAmount);

        emit LinearVestingClaimed(msg.sender, launchId, claimAmount);
    }

    function commitUnclaimedSkill(uint256 launchId, uint256 amount, address whitelistedWallet) external isUserWhitelistedForLaunch(whitelistedWallet, launchId) launchNotStarted(launchId) onlyPhase1(launchId) {
        uint256 windowStartTime = launchStartTime[launchId].sub(vars[VAR_UNCLAIMED_COMMIT_START_OFFSET]);
        require(block.timestamp >= windowStartTime && block.timestamp <= windowStartTime.add(vars[VAR_UNCLAIMED_COMMIT_WINDOW]), "Not a commit window");
        uint256 committingValue = amount.mul(skillPrice).div(1e18);
        require((launchTotalUnclaimedSkillCommittedValue[launchId].add(committingValue)).mul(vars[VAR_UNCLAIMED_TO_ALLOCATION_MULTIPLIER]) <= vars[VAR_UNCLAIMED_ALLOCATION_PERCENTAGE].mul(launchFundsToRaise[launchId]).div(100), "Unclaimed limit reached");
        _game.deductAfterPartnerClaim(amount, msg.sender);
        launchUserUnclaimedSkillCommittedValue[launchId][whitelistedWallet] += committingValue;
        launchTotalUnclaimedSkillCommittedValue[launchId] += committingValue;
        
        emit SkillCommitted(msg.sender, whitelistedWallet, launchId, amount);
    }
}
