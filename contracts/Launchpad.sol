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

    struct Launch {
        string name;
        string tokenSymbol;
        string details;
        string imageUri;
        address fundingTokenAddress;
        uint256 phase;
    }

    // VARS
    mapping(uint256 => uint256) public vars;
    uint256 public VAR_TIERS_AMOUNT = 1;
    uint256 public VAR_FUNDING_PERIOD_PHASE_1 = 2;
    uint256 public VAR_FUNDING_PERIOD_PHASE_2 = 3;

    // TIERS INFO
    mapping(uint256 => uint256) public tierStakingRequirement;
    mapping(uint256 => uint256) public tierAllocationWeight;

    // LAUNCHPAD PROJECT INFO
    mapping(uint256 => Launch) public launches;
    mapping(uint256 => uint256) public launchTokenPrice;
    mapping(uint256 => uint256) public launchStartTime;
    mapping(uint256 => uint256) public launchAmountToSell;
    mapping(uint256 => uint256) public launchFundsToRaise;
    mapping(uint256 => uint256) public launchBaseAllocation;
    mapping(uint256 => uint256) public launchTotalRaised;
    mapping(uint256 => address) public launchTokenAddress;

    // USER INFO
    mapping(uint256 => EnumerableSet.AddressSet) launchEligibleUsersSnapshot;
    mapping(uint256 => mapping(address => uint256)) public launchUserStakedAmountSnapshot;    
    mapping(uint256 => mapping(address => uint256)) public launchUserInvestment;

    // VESTING INFO
    mapping(uint256 => uint256[]) launchVestingsPercentage;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) userClaimedVestingPortion;


    uint256 public nextLaunchId;

    function initialize() public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        nextLaunchId = 1;
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

    function getAvailabeClaimAmount(address user, uint256 launchId, uint256 vestingId) public view returns (uint256) {
        return launchUserInvestment[launchId][msg.sender].mul(1e18).div(launchTokenPrice[launchId]).mul(launchVestingsPercentage[launchId][vestingId]).div(100);
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

    function addNewLaunch(
        string calldata name,
        string calldata tokenSymbol,
        string calldata details,
        string calldata imageUri,
        address fundingTokenAddress
    ) external restricted {
        launches[nextLaunchId] = Launch(
            name,
            tokenSymbol,
            details,
            imageUri,
            fundingTokenAddress,
            1
        );
        nextLaunchId += 2;
    }

    function addSecondPhaseForLaunch(uint256 launchId, uint256 startTime) external restricted {
        Launch memory lp = launches[launchId];
        launches[launchId + 1] = Launch(
            lp.name,
            lp.tokenSymbol,
            lp.details,
            lp.imageUri,
            lp.fundingTokenAddress,
            2
        );
        
        launchStartTime[launchId + 1] = startTime;
        launchTokenPrice[launchId + 1] = launchTokenPrice[launchId];
        launchAmountToSell[launchId + 1] = launchAmountToSell[launchId].sub(launchTotalRaised[launchId].mul(1e18).div(launchTokenPrice[launchId]));
        launchFundsToRaise[launchId + 1] = launchFundsToRaise[launchId].sub(launchTotalRaised[launchId]);
        launchBaseAllocation[launchId + 1] = launchBaseAllocation[launchId];
        launchTokenAddress[launchId + 1] = launchTokenAddress[launchId];
    }

    function removeLaunch(uint256 launchId) external restricted {
        delete launches[launchId];
    }

    function updateLaunchTokenPrice(uint256 launchId, uint256 tokenPrice) external restricted {
        launchTokenPrice[launchId] = tokenPrice;
    }

    function updateLaunchFundingTokenAddress(uint256 launchId, address fundingTokenAddress) external restricted {
        launches[launchId].fundingTokenAddress = fundingTokenAddress;
    }

    function updateLaunchStartTime(uint256 launchId, uint256 startTime) external restricted {
        launchStartTime[launchId] = startTime;
    }

    function enableVesting(uint256 launchId, uint256 percentage) external restricted {
        require(launchTokenAddress[launchId] != address(0), "Token address not set");
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

    // USER FUNCTIONS

    function invest(uint256 launchId, uint256 amount) external {
        Launch memory lp = launches[launchId];
        require(launchStartTime[launchId] != 0 && block.timestamp > launchStartTime[launchId], "Launch not started");
        require((lp.phase == 1 && block.timestamp < launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_1])
            || (lp.phase == 2 && block.timestamp < launchStartTime[launchId] + vars[VAR_FUNDING_PERIOD_PHASE_2]), "Launch ended");
        require(launchTokenPrice[launchId] != 0, "Token price not set");
        require(launchTotalRaised[launchId] + amount <= launchFundsToRaise[launchId], "Amount exceeds remaining supply");
        require(getUserMaxAllocationForLaunch(msg.sender, launchId) >= amount, "Allocation allowance exceeded");

        IERC20(lp.fundingTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        launchUserInvestment[launchId][msg.sender] += amount;
        launchTotalRaised[launchId] += amount;
    }

    function claim(uint256 launchId, uint256 vestingId) external {
        require(vestingId > 0 && launchVestingsPercentage[launchId].length >= vestingId, "Vesting unavailable");
        require(!userClaimedVestingPortion[msg.sender][launchId][vestingId], "Vesting already claimed");

        userClaimedVestingPortion[msg.sender][launchId][vestingId] = true;
        uint256 claimAmount = getAvailabeClaimAmount(msg.sender, launchId, vestingId);
        IERC20(launchTokenAddress[launchId]).safeTransferFrom(address(this), msg.sender, claimAmount);
    }
}
