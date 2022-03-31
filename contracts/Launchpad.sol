pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Launchpad is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    struct LaunchpadProject {
        string name;
        string tokenSymbol;
        string details;
        string imageUri;
        uint256 tokenPrice;
        uint256 startTime;
        uint256 fundsToRaise;
        address fundingTokenAddress;
        uint256 phase;
    }

    mapping(uint256 => uint256) public vars;
    uint256 public VAR_TIERS_AMOUNT = 1;
    uint256 public VAR_FUNDING_PERIOD_PHASE_1 = 2;
    uint256 public VAR_FUNDING_PERIOD_PHASE_2 = 3;

    mapping(uint256 => uint256) public tierStakingRequirement;
    mapping(uint256 => uint256) public tierAllocationWeight;
    mapping(uint256 => LaunchpadProject) public launchpadProjects;
    mapping(uint256 => uint256) public launchpadProjectTotalRaised;
    mapping(uint256 => mapping(address => uint256)) public userInvestment;
    mapping(uint256 => uint256) public launchBaseAllocation;
    mapping(uint256 => EnumerableSet.AddressSet) launchEligibleUsersSnapshot;
    mapping(uint256 => mapping(address => uint256)) public launchUserStakedAmountSnapshot;
    mapping(uint256 => mapping(uint256 => uint256)) public launchVestingPercentage;

    uint256 public nextLaunchpadProjectId;

    function initialize() public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        nextLaunchpadProjectId = 1;
    }

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
            if (amount > tierStakingRequirement[i]) {
                tier++;
            } else {
                break;
            }
        }
    }

    function getLaunchAllocationForTier(uint256 launchId, uint256 tier) public view returns (uint256) {
        return launchBaseAllocation[launchId].mul(tierAllocationWeight[tier]);
    }

    function getUserMaxAllocationForLaunch(address user, uint256 launchId) public view returns (uint256) {
        return getLaunchAllocationForTier(launchId, getTierForStakedAmount(launchUserStakedAmountSnapshot[launchId][user]));
    }

    // RESTRICTED FUNCTIONS

    // TIERS

    function setBrandNewTiers( uint256[] calldata tierIds, uint256[] calldata stakingRequirements, uint256[] calldata tierWeights) external restricted {
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

    function addNewLaunchpadProject(
        string calldata name,
        string calldata tokenSymbol,
        string calldata details,
        string calldata imageUri,
        uint256 tokenPrice,
        uint256 startTime,
        uint256 fundsToRaise,
        address fundingTokenAddress
    ) external restricted {
        launchpadProjects[nextLaunchpadProjectId] = LaunchpadProject(
            name,
            tokenSymbol,
            details,
            imageUri,
            tokenPrice,
            startTime,
            fundsToRaise,
            fundingTokenAddress,
            1
        );
        nextLaunchpadProjectId += 2;
    }

    function addSecondPhaseForLaunch(uint256 launchId, uint256 startTime) external restricted {
        LaunchpadProject memory lp = launchpadProjects[launchId];
        launchpadProjects[launchId + 1] = LaunchpadProject(
            lp.name,
            lp.tokenSymbol,
            lp.details,
            lp.imageUri,
            lp.tokenPrice,
            startTime,
            lp.fundsToRaise.sub(launchpadProjectTotalRaised[launchId]),
            lp.fundingTokenAddress,
            2
        );
    }

    function removeLaunchpadProject(uint256 id) external restricted {
        delete launchpadProjects[id];
    }

    function updateLaunchpadProjectTokenPrice(uint256 id, uint256 tokenPrice) external restricted {
        launchpadProjects[id].tokenPrice = tokenPrice;
    }

    function updateLaunchpadProjectFundingTokenAddress( uint256 id, address fundingTokenAddress) external restricted {
        launchpadProjects[id].fundingTokenAddress = fundingTokenAddress;
    }

    function updateLaunchpadProjectStartTime(uint256 id, uint256 startTime) external restricted {
        launchpadProjects[id].startTime = startTime;
    }

    function enableVesting(uint256 launchId, uint256 percentage) external restricted {
        
    }

    // WHITELISTING

    function setEligibleUsersData(uint256 launchId, address[] calldata users, uint256[] calldata stakedAmounts) external restricted {
        LaunchpadProject memory lp = launchpadProjects[launchId];
        require(nextLaunchpadProjectId >= launchId, "Wrong launch ID");
        require(users.length == stakedAmounts.length, "Wrong input");
        require(lp.startTime > block.timestamp, "Event already started");

        uint totalWeight = 0;
        for(uint i = 0; i < users.length; i++) {
            launchEligibleUsersSnapshot[launchId].add(users[i]);
            launchUserStakedAmountSnapshot[launchId][users[i]] = stakedAmounts[i];
            totalWeight += tierAllocationWeight[getTierForStakedAmount(stakedAmounts[i])];
        }
        launchBaseAllocation[launchId] = lp.fundsToRaise.div(totalWeight);
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

    // USER FUNCTIONS

    function invest(uint256 launchId, uint256 amount) external {
        LaunchpadProject memory lp = launchpadProjects[launchId];
        require(lp.startTime != 0 && block.timestamp > lp.startTime, "Launch not started");
        require(lp.tokenPrice != 0, "Token price not set");
        require((lp.phase == 1 && block.timestamp < lp.startTime + vars[VAR_FUNDING_PERIOD_PHASE_1]) || (lp.phase == 2 && block.timestamp < lp.startTime + vars[VAR_FUNDING_PERIOD_PHASE_2]), "Launch ended");
        require(launchpadProjectTotalRaised[launchId] + amount <= lp.fundsToRaise, "Amount exceeds remaining supply");
        require(getUserMaxAllocationForLaunch(msg.sender, launchId) >= amount, "Allocation allowance exceeded");

        IERC20(lp.fundingTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        userInvestment[launchId][msg.sender] += amount;
        launchpadProjectTotalRaised[launchId] += amount;
    }
}
