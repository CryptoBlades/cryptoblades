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

    function get(uint256 id) public view returns (uint256, uint256, uint256, uint256, uint256, bool) {
        return (landData[id][LT], landData[id][LC], landData[id][LX], landData[id][LY], id, landBoolData[id][LBT]);
    }

    // tier, chunkid, x, y, id, isToken (id was added later, that's why not first)
    function getOwned(address owner) public view returns (uint256, uint256, uint256, uint256, uint256, bool) {
        uint256 id = tokenOfOwnerByIndex(owner, 0);
        return get(id);
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

    function mintLandToken(address reseller, address minter, uint256 tier) public restricted {
        uint256 tokenID = landMinted++;
        
        landData[tokenID][LT] = tier;
        landBoolData[tokenID][LBT] = true;
        landAddressData[tokenID][LAR] = reseller;

        _mint(minter, tokenID);
        emit LandTokenMinted(reseller, minter, tokenID, tier);
    }

    function getLandTierURI(uint256 id) public view returns (string memory uri) {
       (uint256 tier,,,,,) = get(id);
        return getTierURI(tier);
    }

    function getTierURI(uint256 tier) public view returns (string memory uri) {
        return tierStrData[tier][TSU];
    }

    function setTierStr(uint256 tier, uint256 index, string memory val) public restricted {
        tierStrData[tier][index] = val;
    }

    // TODO: block land transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, to)) {
            require(balanceOf(to) == 0, "Recv has purchased a land");
        }

        emit LandTransfered(from, to, tokenId);
    }
}
