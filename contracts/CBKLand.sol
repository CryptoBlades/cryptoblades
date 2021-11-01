pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";

contract CBKLand is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");

    // Land specific
    uint256 public constant LT = 0; // Land Tier
    uint256 public constant LC = 1; // Land Chunk Id
    uint256 public constant LX = 2; // Land Coordinate X
    uint256 public constant LY = 3; // Land Coordinate Y
    

    event LandMinted(address indexed minter, uint256 id, uint256 tier, uint256 chunkId);
    event LandTransfered(address indexed from, address indexed to, uint256 id);
    event LandTokenMinted(address indexed reseller, address indexed minter, uint256 id, uint256 tier);
    event LandMintedWithReseller(address indexed minter, uint256 id, uint256 tier, uint256 chunkId, address reseller);

    // TotalLand
    uint256 landMinted;
    // Avoiding structs for stats
    mapping(uint256 => mapping(uint256 => uint256)) landData;

    mapping(uint256 => mapping(uint256 => string)) landStrData;

    uint256 public constant LBT = 0; // Land is a Token, it will have its chunkId updated later
    mapping(uint256 => mapping(uint256 => bool)) landBoolData;

    uint256 public constant LAR = 0; // Land Reseller, the one who minted the token
    mapping(uint256 => mapping(uint256 => address)) landAddressData;

    uint256 public constant TSU = 0; // URI of a tier. Will put this in land NFT because it kinda belongs here
    mapping(uint256 => mapping(uint256 => string)) tierStrData;

    function initialize () public initializer {
        __ERC721_init("CryptoBladesKingdoms Land", "CBKL");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

     // tier, chunkid, x, y
    function get(uint256 id) public view returns (uint256, uint256, uint256, uint256) {
        return (landData[id][LT], landData[id][LC], landData[id][LX], landData[id][LY]);
    }

    function getOwned(address owner) public view returns (uint256[] memory ownedIds) {
        uint256 ownedLandCount = balanceOf(owner);
        ownedIds = new uint256[](ownedLandCount);
         for(uint256 i = 0; i < ownedLandCount; i++) {
             ownedIds[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    function getLandReseller(uint256 land) public view returns (address) {
        return landAddressData[land][LAR];
    }

    // DO NOT call directly outside the logic of CBKLandSale to avoid breaking tier and chunk logic
    function mint(address minter, uint256 tier, uint256 chunkId) public restricted {
        uint256 tokenID = landMinted++;
        
        landData[tokenID][LT] = tier;
        landData[tokenID][LC] = chunkId;
        //landData[tokenID][LX] = x; // not yet
        //landData[tokenID][LY] = y; // not yet
        
        _mint(minter, tokenID);
        emit LandMinted(minter, tokenID, tier, chunkId);
    }

    function mint(address minter, uint256 tier, uint256 chunkId, address reseller) public restricted {
        uint256 tokenID = landMinted++;
        
        landData[tokenID][LT] = tier;
        landData[tokenID][LC] = chunkId;
        //landData[tokenID][LX] = x; // not yet
        //landData[tokenID][LY] = y; // not yet
        
        landAddressData[tokenID][LAR] = reseller;

        _mint(minter, tokenID);
        emit LandMintedWithReseller(minter, tokenID, tier, chunkId, reseller);
    }


    function getLandTierURI(uint256 id) public view returns (string memory uri) {
       (uint256 tier,,,) = get(id);
        return getTierURI(tier);
    }

    function getTierURI(uint256 tier) public view returns (string memory uri) {
        return tierStrData[tier][TSU];
    }

    function setTierStr(uint256 tier, uint256 index, string memory val) public restricted {
        tierStrData[tier][index] = val;
    }
}
