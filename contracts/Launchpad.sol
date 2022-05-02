pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

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
    }

    // VARS
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_TIERS_AMOUNT = 1;
    uint256 public constant VAR_FUNDING_PERIOD_PHASE_1 = 2;
    uint256 public constant VAR_FUNDING_PERIOD_PHASE_2 = 3;
    uint256 public constant VAR_UNCLAIMED_TO_ALLOCATION_MULTIPLIER = 4;
    uint256 public constant VAR_UNCLAIMED_ALLOCATION_PERCENTAGE = 5;
    

    // TIERS INFO
    mapping(uint256 => uint256) public tierStakingRequirement;
    mapping(uint256 => uint256) public tierAllocationWeight;

    // LAUNCHPAD PROJECT INFO
    mapping(uint256 => Launch) public launches;
    mapping(uint256 => uint256) public launchTokenPrice;
    mapping(uint256 => uint256) public launchStartTime;
    //mapping(uint256 => uint256) public launchAmountToSell;
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

    // VESTING INFO
    mapping(uint256 => uint256[]) launchVestingsPercentage;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) userClaimedVestingPortion;


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
    event SkillCommitted(address indexed user, uint256 indexed launchId, uint256 amount);
    event VestingClaimed(address indexed user, uint256 indexed launchId, uint256 indexed vestingId, uint256 amount);

    // MODIFIERS
    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
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
        maxAllocation = getLaunchAllocationForTier(launchId, getTierForStakedAmount(launchUserStakedAmountSnapshot[launchId][user]));
        maxAllocation += launchUserUnclaimedSkillCommittedValue[launchId][user].mul(vars[VAR_UNCLAIMED_TO_ALLOCATION_MULTIPLIER]);
        maxAllocation = maxAllocation.sub(launchUserInvestment[launchId][user]);
    }

    function getAvailableClaimAmount(address user, uint256 launchId, uint256 vestingId) public view returns (uint256 claimAmount) {
        uint256 decimals = ERC20(launchTokenAddress[launchId]).decimals();
        claimAmount = launchUserInvestment[launchId][user].mul(1e18).div(launchTokenPrice[launchId]).mul(launchVestingsPercentage[launchId][vestingId]).div(100);
        if(decimals > 18) {
            claimAmount = claimAmount.mul(10**uint(decimals - 18));
        } else {
            claimAmount = claimAmount.div(10**uint(18 - decimals));
        }
    }

    function getLaunchBaseInfo(uint256 launchId) public view returns (
        string memory name,
        string memory tokenSymbol,
        string memory detailsJsonUri,
        string memory imageUrl,
        address fundingTokenAddress,
        uint256 phase) {
        Launch memory l = launches[launchId];
        name = l.name;
        tokenSymbol= l.tokenSymbol;
        detailsJsonUri = l.detailsJsonUri;
        imageUrl = l.imageUrl;
        fundingTokenAddress = l.fundingTokenAddress;
        phase = l.phase;
    }

    function getLaunchDetails(uint256 launchId) public view returns (
        uint256 tokenPrice,
        uint256 startTime, 
        //uint256 amountToSell,
        uint256 fundsToRaise,
        uint256 maxAllocation,
        uint256 totalRaised,
        address tokenAddress) 
    {
        tokenPrice = launchTokenPrice[launchId];
        startTime = launchStartTime[launchId];
        //amountToSell = launchAmountToSell[launchId];
        fundsToRaise = launchFundsToRaise[launchId];
        maxAllocation = getOverallMaxAllocation(launchId);
        totalRaised = launchTotalRaised[launchId];
        tokenAddress = launchTokenAddress[launchId];
    }

    function getOverallMaxAllocation(uint256 launchId) public view returns (uint256) {
        return getLaunchAllocationForTier(launchId, vars[VAR_TIERS_AMOUNT]);
    }

    function isSenderWhitelisted(uint256 launchId) public view returns (bool) {
        return launchEligibleUsersSnapshot[launchId].contains(msg.sender);
    }

    function getTotalUnlockedPercentage(uint256 launchId) public view returns (uint256 totalUnlockedPercentage) {
        for(uint i = 0; i < launchVestingsPercentage[launchId].length; i++) {
            totalUnlockedPercentage += launchVestingsPercentage[launchId][i];
        }
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
        address fundingTokenAddress
    ) external restricted {
        launches[nextLaunchId] = Launch(
            name,
            tokenSymbol,
            detailsJsonUri,
            imageUrl,
            fundingTokenAddress,
            1
        );

        emit LaunchAdded(nextLaunchId, 1);
        nextLaunchId += 2;
    }

    function addSecondPhaseForLaunch(uint256 launchId, uint256 startTime) external restricted {
        Launch memory lp = launches[launchId];
        require(block.timestamp > launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_1], "Phase 1 not finished");
        require(launchFundsToRaise[launchId].sub(launchTotalRaised[launchId]) > 0, "Tokens sold out");
        launches[launchId + 1] = Launch(
            lp.name,
            lp.tokenSymbol,
            lp.detailsJsonUri,
            lp.imageUrl,
            lp.fundingTokenAddress,
            2
        );
        
        launchStartTime[launchId + 1] = startTime;
        launchTokenPrice[launchId + 1] = launchTokenPrice[launchId];
        //launchAmountToSell[launchId + 1] = launchAmountToSell[launchId].sub(launchTotalRaised[launchId].mul(1e18).div(launchTokenPrice[launchId]));
        launchFundsToRaise[launchId + 1] = launchFundsToRaise[launchId].sub(launchTotalRaised[launchId]);
        launchBaseAllocation[launchId + 1] = launchBaseAllocation[launchId];
        launchTokenAddress[launchId + 1] = launchTokenAddress[launchId];

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

    function updateLaunchFundingTokenAddress(uint256 launchId, address fundingTokenAddress) external restricted {
        launches[launchId].fundingTokenAddress = fundingTokenAddress;
    }

    function updateLaunchTokenPrice(uint256 launchId, uint256 tokenPrice) external restricted {
        launchTokenPrice[launchId] = tokenPrice;
    }

    function updateLaunchStartTime(uint256 launchId, uint256 startTime) external restricted {
        launchStartTime[launchId] = startTime;
    }

    function updateLaunchFundsToRaise(uint256 launchId, uint256 fundsToRaise) external restricted {
        launchFundsToRaise[launchId] = fundsToRaise;
    }

    // VESTING

    function enableVesting(uint256 launchId, uint256 percentage) external restricted {
        require(launchTokenAddress[launchId] != address(0), "Token address not set");
        require(getTotalUnlockedPercentage(launchId) + percentage <= 100, "Total percentage exceeded");
        require(IERC20(launchTokenAddress[launchId]).balanceOf(address(this)) >=
            launchTotalRaised[launchId].mul(1e18).div(launchTokenPrice[launchId]).mul(getTotalUnlockedPercentage(launchId) + percentage).div(100),
            "Not enough balance");
        //require(IERC20(launchTokenAddress[launchId]).balanceOf(address(this)) >= launchPad);
        launchVestingsPercentage[launchId].push(percentage);
    }

    // WHITELISTING

    function setEligibleUsersData(uint256 launchId, address[] calldata users, uint256[] calldata stakedAmounts) external restricted {
        require(nextLaunchId >= launchId, "Wrong launch ID");
        require(users.length == stakedAmounts.length, "Wrong input");
        require(launchStartTime[launchId] > block.timestamp, "Event already started");

        uint totalWeight = 0;
        for(uint i = 0; i < users.length; i++) {
            launchEligibleUsersSnapshot[launchId].add(users[i]);
            launchUserStakedAmountSnapshot[launchId][users[i]] = stakedAmounts[i];
            totalWeight += tierAllocationWeight[getTierForStakedAmount(stakedAmounts[i])];
        }
        launchBaseAllocation[launchId] = launchFundsToRaise[launchId].div(totalWeight);
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

    function invest(uint256 launchId, uint256 amount) external {
        Launch memory lp = launches[launchId];
        require(launchStartTime[launchId] != 0 && block.timestamp > launchStartTime[launchId], "Launch not started");
        require((lp.phase == 1 && block.timestamp < launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_1])
            || (lp.phase == 2 && block.timestamp < launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_2]), "Launch ended");
        require(launchTokenPrice[launchId] != 0, "Token price not set");
        require(launchTotalRaised[launchId] + amount <= launchFundsToRaise[launchId], "Amount exceeds remaining supply");
        require(getUserRemainingAllocationForLaunch(msg.sender, launchId) >= amount, "Allocation allowance exceeded");
        require(launchEligibleUsersSnapshot[launchId].contains(msg.sender), "Not whitelisted");

        IERC20(lp.fundingTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        launchUserInvestment[launchId][msg.sender] += amount;
        launchTotalRaised[launchId] += amount;

        emit Invested(msg.sender, amount);
    }

    function claim(uint256 launchId, uint256 vestingId) external {
        require(vestingId > 0 && launchVestingsPercentage[launchId].length >= vestingId, "Vesting unavailable");
        require(!userClaimedVestingPortion[msg.sender][launchId][vestingId], "Vesting already claimed");

        userClaimedVestingPortion[msg.sender][launchId][vestingId] = true;
        uint256 claimAmount = getAvailableClaimAmount(msg.sender, launchId, vestingId);
        IERC20(launchTokenAddress[launchId]).safeTransferFrom(address(this), msg.sender, claimAmount);

        emit VestingClaimed(msg.sender, launchId, vestingId, claimAmount);
    }

    function commitUnclaimedSkill(uint256 launchId, uint256 amount) external {
        require(isSenderWhitelisted(launchId), "Not whitelisted");
        uint256 committingValue = amount.mul(skillPrice).div(1e18);
        require((launchTotalUnclaimedSkillCommittedValue[launchId].add(committingValue)).mul(vars[VAR_UNCLAIMED_TO_ALLOCATION_MULTIPLIER]).div(1e18) <= vars[VAR_UNCLAIMED_ALLOCATION_PERCENTAGE].mul(launchFundsToRaise[launchId]).div(100));
        _game.deductAfterPartnerClaim(amount, msg.sender);
        launchUserUnclaimedSkillCommittedValue[launchId][msg.sender] += committingValue;
        launchTotalUnclaimedSkillCommittedValue[launchId] += committingValue;
        launchBaseAllocation[launchId] = launchBaseAllocation[launchId].sub(launchBaseAllocation[launchId].mul(launchTotalUnclaimedSkillCommittedValue[launchId]).div(launchFundsToRaise[launchId]));
        
        emit SkillCommitted(msg.sender, launchId, amount);
    }
}
