pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./cryptoblades.sol";

contract Treasury is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;
    using SafeERC20 for IERC20;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    uint256 public multiplierUnit;

    PartnerProject[] private partneredProjects;
    mapping(uint256 => uint256) projectAddedBlockNumber;
    mapping(uint256 => uint256) tokensClaimed;
    uint256 skillPrice;

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

    function initialize(CryptoBlades _game) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        game = _game;
        // each block increases payout by 0.0001x
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

    function getAmountOfActiveProjects() public view returns (uint256) {
      uint256 activeCount = 0;
        for(uint i = 0; i < partneredProjects.length; i++) {
            if(partneredProjects[i].isActive) {
              activeCount += 1;
            }
        }
        return activeCount;
    }

    function getActivePartnerProjectsIds() public view returns (uint256[] memory){
        uint256 activeCount = getAmountOfActiveProjects();
        uint256 counter = 0;
        
        uint256[] memory activeProjectsIds = new uint256[](activeCount);
        for(uint i = 0; i < partneredProjects.length; i++) {
            if(partneredProjects[i].isActive) {
              activeProjectsIds[counter] = i;
              counter++;
            }
        }

        return activeProjectsIds;
    }

    function getPartnerProject(uint256 partnerId) public view returns(uint256, string memory, string memory, address, uint256, uint256, uint256, bool) {
        PartnerProject memory p = partneredProjects[partnerId];
        uint256 claimed = tokensClaimed[partnerId];
        return(p.id, p.name, p.tokenSymbol, p.tokenAddress, p.tokenSupply, claimed, p.tokenPrice, p.isActive);
    }

    function getProjectMultiplier(uint256 partnerId) public view returns(uint256) {
        return uint(1e18).div(multiplierUnit).mul(block.number.sub(projectAddedBlockNumber[partnerId])).add(1e18);
    }

    function getProjectClaimedAmount(uint256 partnerId) public view returns(uint256) {
        return tokensClaimed[partnerId];
    }

    function getSkillToPartnerRatio(uint256 partnerId) public view returns(int128) {
        return ABDKMath64x64.divu(skillPrice, partneredProjects[partnerId].tokenPrice);
    }

    function getRemainingPartnerTokenSupply(uint256 partnerId) public view returns(uint256) {
        return  IERC20(partneredProjects[partnerId].tokenAddress).balanceOf(address(this));
    }

    function getAmountInPartnerToken(uint256 partnerId, uint256 skillAmount) public view returns(uint256) {
        uint256 baseAmount = getSkillToPartnerRatio(partnerId).mulu(skillAmount);
        uint256 bonusAmount = baseAmount.mul(block.number.sub(projectAddedBlockNumber[partnerId])).div(multiplierUnit);
        return baseAmount.add(bonusAmount);
    }

    // Mutative

    function addPartnerProject(
        string memory name,
        string memory tokenSymbol,
        address tokenAddress,
        uint256 tokenSupply,
        uint256 tokenPrice,
        bool isActive)
    public restricted {
        uint256 id = partneredProjects.length;
        projectAddedBlockNumber[id] = block.number;
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
    }

    function claim(uint256 partnerId) public {
        claim(partnerId, game.getTokenRewardsFor(msg.sender));
    }

    function claim(uint256 partnerId, uint256 skillClaimingAmount) public {
        require(game.getTokenRewardsFor(msg.sender) >= skillClaimingAmount, 'Claim amount exceeds available rewards balance');

        uint256 partnerTokenAmount = getAmountInPartnerToken(partnerId, skillClaimingAmount);
        uint256 remainingPartnerTokenSupply = getRemainingPartnerTokenSupply(partnerId);
        uint256 skillToDeduct = skillClaimingAmount;

        if(partnerTokenAmount > remainingPartnerTokenSupply) {
            partnerTokenAmount = remainingPartnerTokenSupply;
            skillToDeduct = skillToDeduct.mul(remainingPartnerTokenSupply.div(partnerTokenAmount));
        }
        
        game.deductAfterPartnerClaim(skillToDeduct, msg.sender);
        tokensClaimed[partnerId] += partnerTokenAmount;
        IERC20(partneredProjects[partnerId].tokenAddress).safeTransfer(msg.sender, partnerTokenAmount);
    }

    function setMultiplierUnit(uint256 unit) public restricted {
        multiplierUnit = unit;
    }

    function setIsActive(uint256 id, bool isActive) public restricted {
        partneredProjects[id].isActive = isActive;
    }

    function setSkillPrice(uint256 newPrice) public restricted {
        require(newPrice > 0);
        skillPrice = newPrice;
    }

    function setPartnerTokenPrice(uint256 partnerId, uint256 newPrice) public restricted {
        require(newPrice > 0);
        partneredProjects[partnerId].tokenPrice = newPrice;
    }
}