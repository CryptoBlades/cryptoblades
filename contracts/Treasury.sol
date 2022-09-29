pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./cryptoblades.sol";

contract Treasury is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;
    using SafeERC20 for IERC20;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    uint256 public constant GAMEUSERVAR_GEN2_UNCLAIMED = 10011;

    uint256 public multiplierUnit;

    PartnerProject[] public partneredProjects;
    mapping(uint256 => uint256) projectAddedBlockNumber;
    mapping(uint256 => uint256) public tokensClaimed;
    uint256 public skillPrice;

    event TreasuryClaimed(address indexed sender, uint256 indexed partnerId, uint256 claimedAmount, uint256 currentMultiplier);

    struct PartnerProject {
        uint256 id;
        string name;
        string tokenSymbol;
        address tokenAddress;
        uint256 tokenSupply;
        uint256 tokenPrice;
        bool isActive;
    }

    CryptoBlades public game;

    mapping(uint256 => uint256) public projectDistributionTime;
    mapping(uint256 => uint256) multiplierTimestamp;
    uint256 public defaultSlippage;
    mapping(uint256 => string) public projectLogo;
    mapping(uint256 => string) public projectDetails;
    mapping(uint256 => string) public projectWebsite;
    mapping(uint256 => string) public projectNote;
    mapping(uint256 => bool) public projectIsValor;

    function initialize(CryptoBlades _game) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        game = _game;
        // multiplier increases every second by 1e18/multiplierUnit
        multiplierUnit = 1e4;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    // Views

    function getAmountOfActiveProjects() public view returns (uint256 activeCount) {
        activeCount = 0;
        for (uint i; i < partneredProjects.length; i++) {
            if (partneredProjects[i].isActive) {
                activeCount += 1;
            }
        }
    }

    function getActivePartnerProjectsIds() public view returns (uint256[] memory activeProjectsIds){
        uint256 activeCount = getAmountOfActiveProjects();
        uint256 counter = 0;

        activeProjectsIds = new uint256[](activeCount);
        for (uint i = 0; i < partneredProjects.length; i++) {
            if (partneredProjects[i].isActive) {
                activeProjectsIds[counter] = i;
                counter++;
            }
        }
    }

    function getProjectMultiplier(uint256 partnerId) public view returns (uint256) {
        if (block.timestamp >= multiplierTimestamp[partnerId]) {
            return uint(1e18).div(multiplierUnit).mul(block.timestamp.sub(multiplierTimestamp[partnerId])).add(1e18);
        }
        uint256 multiplierDecrease = uint(1e18).div(multiplierUnit).mul(multiplierTimestamp[partnerId].sub(block.timestamp));
        if (multiplierDecrease > 1e18) {
            return 0;
        }
        return uint(1e18).sub(multiplierDecrease);
    }

    function getSkillToPartnerRatio(uint256 partnerId) public view returns (int128) {
        return ABDKMath64x64.divu(skillPrice, partneredProjects[partnerId].tokenPrice);
    }

    function getRemainingPartnerTokenSupply(uint256 partnerId) public view returns (uint256) {
        return partneredProjects[partnerId].tokenSupply.mul(1e18).sub(tokensClaimed[partnerId]);
    }

    function getAmountInPartnerToken(uint256 partnerId, uint256 claimingAmount) public view returns (uint256 amountWithMultiplier) {
        uint256 baseAmount;
        if(projectIsValor[partnerId]) {
            // Valor/Valor = 1:1
            baseAmount = claimingAmount; 
        }
        else {
            baseAmount = getSkillToPartnerRatio(partnerId).mulu(claimingAmount);
        }
        amountWithMultiplier = baseAmount.mul(getProjectMultiplier(partnerId)).div(1e18);
    }

    function getAmountWithAdjustedDecimals(uint256 partnerTokenAmount, uint256 partnerTokenDecimals) internal pure returns (uint256 partnerTokenAmountAdjusted) {
        if (partnerTokenDecimals > 18) {
            partnerTokenAmountAdjusted = partnerTokenAmount.mul(10 ** uint(partnerTokenDecimals - 18));
        } else {
            partnerTokenAmountAdjusted = partnerTokenAmount.div(10 ** uint(18 - partnerTokenDecimals));
        }
    }

    function getProjectData(uint256 partnerId) public view returns (string memory, string memory, string memory, string memory) {
        return (projectLogo[partnerId], projectDetails[partnerId], projectWebsite[partnerId], projectNote[partnerId]);
    }

    // Mutative

    function addPartnerProject(
        string memory name,
        string memory tokenSymbol,
        address tokenAddress,
        uint256 tokenSupply,
        uint256 tokenPrice,
        uint256 distributionTime,
        bool isActive,
        string memory logo,
        string memory details,
        string memory website,
        string memory note,
        bool isValor)
    public restricted {
        uint256 id = partneredProjects.length;
        multiplierTimestamp[id] = block.timestamp;
        tokensClaimed[id] = 0;
        partneredProjects.push(PartnerProject(
                id,
                name,
                tokenSymbol,
                tokenAddress,
                tokenSupply,
                tokenPrice,
                isActive
            ));
        projectDistributionTime[id] = distributionTime;
        projectLogo[id] = logo;
        projectDetails[id] = details;
        projectWebsite[id] = website;
        projectNote[id] = note;
        projectIsValor[id] = isValor;
    }

    function claim(uint256 partnerId) public {
        uint256 claimingAmount;
        if(projectIsValor[partnerId]) {
            claimingAmount = game.userVars(msg.sender,GAMEUSERVAR_GEN2_UNCLAIMED);
        }
        else {
            claimingAmount = game.getTokenRewardsFor(msg.sender);
        }
        claim(partnerId, claimingAmount, getProjectMultiplier(partnerId), defaultSlippage);
    }

    function claim(uint256 partnerId, uint256 claimingAmount, uint256 currentMultiplier, uint256 slippage) public {
        if(projectIsValor[partnerId]) {
            require(game.userVars(msg.sender,GAMEUSERVAR_GEN2_UNCLAIMED) >= claimingAmount, 'Claim amount exceeds available rewards balance');
        }
        else {
            require(game.getTokenRewardsFor(msg.sender) >= claimingAmount, 'Claim amount exceeds available rewards balance');
        }
        uint256 effectiveMultiplier = getProjectMultiplier(partnerId);
        require(currentMultiplier.mul(uint(1e18).sub(slippage)).div(1e18) < effectiveMultiplier, 'Slippage exceeded');
        require(partneredProjects[partnerId].isActive == true, 'Project inactive');

        uint256 partnerTokenAmount = getAmountInPartnerToken(partnerId, claimingAmount);
        uint256 remainingPartnerTokenSupply = getRemainingPartnerTokenSupply(partnerId);
        uint256 tokensToDeduct = claimingAmount;

        if (partnerTokenAmount > remainingPartnerTokenSupply) {
            tokensToDeduct = tokensToDeduct.mul(remainingPartnerTokenSupply).div(partnerTokenAmount);
            partnerTokenAmount = remainingPartnerTokenSupply;
        }

        if(projectIsValor[partnerId]) {
            game.deductValor(tokensToDeduct, msg.sender);
        }
        else {
            game.deductAfterPartnerClaim(tokensToDeduct, msg.sender);
        }
        tokensClaimed[partnerId] += partnerTokenAmount;

        uint256 partnerTokenDecimals = ERC20(partneredProjects[partnerId].tokenAddress).decimals();
        IERC20(partneredProjects[partnerId].tokenAddress).safeTransfer(msg.sender, getAmountWithAdjustedDecimals(partnerTokenAmount, partnerTokenDecimals));

        multiplierTimestamp[partnerId] = multiplierTimestamp[partnerId].add(partnerTokenAmount.div(partneredProjects[partnerId].tokenSupply.div(projectDistributionTime[partnerId])).div(uint(1e18).div(multiplierUnit)));

        emit TreasuryClaimed(msg.sender, partnerId, partnerTokenAmount, effectiveMultiplier);
    }

    // Setters

    function setMultiplierUnit(uint256 unit) external restricted {
        multiplierUnit = unit;
    }

    function setIsActive(uint256 id, bool isActive) public restricted {
        partneredProjects[id].isActive = isActive;
    }

    function setIsValor(uint256 id, bool isValor) public restricted {
        projectIsValor[id] = isValor;
    }

    function setSkillPrice(uint256 newPrice) external restricted {
        require(newPrice > 0);
        skillPrice = newPrice;
    }

    function setPartnerTokenPrice(uint256 partnerId, uint256 newPrice) external restricted {
        require(newPrice > 0);
        partneredProjects[partnerId].tokenPrice = newPrice;
    }

    function setDistributionTime(uint256 partnerId, uint256 distributionTime) external restricted {
        projectDistributionTime[partnerId] = distributionTime;
    }

    function setDefaultSlippage(uint256 newSlippage) external restricted {
        defaultSlippage = newSlippage;
    }

    function setProjectLogo(uint256 partnerId, string calldata logo) external restricted {
        projectLogo[partnerId] = logo;
    }

    function setProjectDetails(uint256 partnerId, string calldata details) external restricted {
        projectDetails[partnerId] = details;
    }

    function setProjectWebsite(uint256 partnerId, string calldata website) external restricted {
        projectWebsite[partnerId] = website;
    }

    function setProjectNote(uint256 partnerId, string calldata note) external restricted {
        projectNote[partnerId] = note;
    }

}
