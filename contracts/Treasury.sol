pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Treasury is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    mapping(address => bool) public partnersWhitelist;
    PartnerProject[] private partneredProjects;

    struct PartnerProject {
        string name;
        string tokenSymbol;
        address tokenAddress;
        uint256 tokenAmount;
        uint256 tokenPrice;
        bool isActive;
    }

    function initialize() public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);
    }
    
    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    function addToWhitelist(address partner) public restricted {
        partnersWhitelist[partner] = true;
    }

    function addPartnerProject(
        string memory name,
        string memory tokenSymbol,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 tokenPrice,
        bool isActive)
    public restricted {
        partneredProjects.push(PartnerProject(
            name,
            tokenSymbol,
            tokenAddress,
            tokenAmount,
            tokenPrice,
            isActive
        ));
    }

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

    function setIsActive(uint256 id, bool isActive) public restricted {
        partneredProjects[id].isActive = isActive;
    }
}