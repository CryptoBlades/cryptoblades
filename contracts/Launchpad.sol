pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./SkillStakingRewardsUpgradeable.sol";

contract Launchpad is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    struct LaunchpadProject {
        uint256 phase;
        string name;
        string tokenSymbol;
        string details;
        string imageUri;
        uint256 tokenPrice;
        uint256 startTime;
        uint256 fundsToRaise;
        address fundingTokenAddress;
    }

    SkillStakingRewardsUpgradeable public skillStaking30days;
    SkillStakingRewardsUpgradeable public skillStaking90days;
    SkillStakingRewardsUpgradeable public skillStaking180days;

    mapping(uint256 => uint256) public vars;
    uint256 public VAR_TIERS_AMOUNT = 1;
    uint256 public VAR_FUNDING_PERIOD_PHASE_1 = 2;
    uint256 public VAR_FUNDING_PERIOD_PHASE_2 = 3;

    mapping(uint256 => uint256) public tierStakingRequirement;
    mapping(uint256 => uint256) public tierAllocationWeight;
    mapping(uint256 => LaunchpadProject) public launchpadProjects;
    mapping(uint256 => uint256) public launchpadProjectTotalRaised;
    mapping(uint256 => mapping(address => uint256)) public userInvestment;

    uint256 latestLaunchpadProjectId;

    function initialize(SkillStakingRewardsUpgradeable _skillStaking30days, SkillStakingRewardsUpgradeable _skillStaking90days, SkillStakingRewardsUpgradeable _skillStaking180days) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        skillStaking30days = _skillStaking30days;
        skillStaking90days = _skillStaking90days;
        skillStaking180days = _skillStaking180days;
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

    function getTotalUserStakedSkill(address user) public view returns (uint256){
        uint256 stakedFor30days = skillStaking30days.balanceOf(user);
        uint256 stakedFor90days = skillStaking30days.balanceOf(user);
        uint256 stakedFor180days = skillStaking30days.balanceOf(user);

        return stakedFor30days + stakedFor90days + stakedFor180days;
    }

    function getUserTier(address user) public view returns (uint256 tier) {
        uint256 totalStakedSkill = getTotalUserStakedSkill(user);
        for(uint i = 1; i <= vars[VAR_TIERS_AMOUNT]; i++) {
            if(totalStakedSkill > tierStakingRequirement[i]) {
                tier++;
            } else {
              break;
            }
        }
    }

    function getLaunchAllocationForTier(uint256 launchId, uint256 tier) {
        
    }

    // RESTRICTED FUNCTIONS

    function setBrandNewTiers(uint256[] calldata tierIds, uint256[] calldata stakingRequirements) external restricted {
        require(tierIds.length == stakingRequirements.length, 'Wrong input');
        vars[VAR_TIERS_AMOUNT] = tierIds.length;
        for(uint i = 0; i < tierIds.length; i++) {
            require(tierIds[i] > 0 && tierIds[i] <= vars[VAR_TIERS_AMOUNT], 'Wrong id');
            tierStakingRequirement[tierIds[i]] = stakingRequirements[i];
        }
    }

    function setTiersRequirements(uint256[] calldata tierIds, uint256[] calldata stakingRequirements) external restricted {
        require(tierIds.length <= vars[VAR_TIERS_AMOUNT], 'Too many tiers');
        require(tierIds.length == stakingRequirements.length, 'Wrong input');
        for(uint i = 0; i < tierIds.length; i++) {
            require(tierIds[i] > 0 && tierIds[i] <= vars[VAR_TIERS_AMOUNT], 'Wrong id');
            tierStakingRequirement[tierIds[i]] = stakingRequirements[i];
        }
    }
    
    function setTiersAllocationWeights(uint256[] calldata tierIds, uint256[] calldata allocationWeights) external restricted {
        require(tierIds.length <= vars[VAR_TIERS_AMOUNT], 'Too many tiers');
        require(tierIds.length == allocationWeights.length, 'Wrong input');
        for(uint i = 0; i < tierIds.length; i++) {
            require(tierIds[i] > 0 && tierIds[i] <= vars[VAR_TIERS_AMOUNT], 'Wrong id');
            tierAllocationWeight[tierIds[i]] = allocationWeights[i];
        }
    }

    function addNewLaunchpadProject(uint256 phase, string calldata name, string calldata tokenSymbol, string calldata details, string calldata image, uint256 tokenPrice, uint256 startTime, uint256 fundsToRaise, address fundingTokenAddress) external restricted {
        latestLaunchpadProjectId++;
        launchpadProjects[latestLaunchpadProjectId] = LaunchpadProject(phase, name, tokenSymbol, details, image, tokenPrice, startTime, fundsToRaise, fundingTokenAddress);
    }

    function removeLaunchpadProject(uint256 id) external restricted {
        delete launchpadProjects[id];
    }

    function updateLaunchpadProjectTokenPrice(uint256 id, uint256 tokenPrice) external restricted {
        launchpadProjects[id].tokenPrice = tokenPrice;
    }

    function updateLaunchpadProjectFundingTokenAddress(uint256 id, address fundingTokenAddress) external restricted {
        launchpadProjects[id].fundingTokenAddress = fundingTokenAddress;
    }

    function updateLaunchpadProjectStartTime(uint256 id, uint256 startTime) external restricted {
        launchpadProjects[id].startTime = startTime;
    }

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    // USER FUNCTIONS

    function invest(uint256 id, uint256 amount, uint256 phase) external {
        LaunchpadProject memory lp = launchpadProjects[id];
        require(lp.startTime != 0 && block.timestamp > lp.startTime, "Launch not started");
        require(lp.tokenPrice != 0, "Token price not set");
        require((lp.phase == 1 && block.timestamp < lp.startTime + vars[VAR_FUNDING_PERIOD_PHASE_1]) || (lp.phase == 2 && block.timestamp < lp.startTime + vars[VAR_FUNDING_PERIOD_PHASE_2]), "Launch ended");
        require(launchpadProjectTotalRaised[id] + amount <= lp.fundsToRaise, "Amount exceeds remaining supply");


    }
}