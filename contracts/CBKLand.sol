pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./util.sol";
import "./CBKLandSale.sol";

contract CBKLand is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");

    uint16 public constant LT = 0; // Land Tier
    uint16 public constant LC = 1; // Land Chunk Id
    uint16 public constant LX = 2; // Land Coordinate X
    uint16 public constant LY = 3; // Land Coordinate Y

    event LandMinted(address indexed minter, uint256 id, uint8 tier, uint16 chunkId, uint256 x, uint256 y);
    event LandTransfered(address indexed from, address indexed to, uint256 id);

    Promos promos;
    CBKLandSale cbkLandSale;

    // TotalLand
    uint256 landMinted;
    // Avoiding structs for stats
    mapping(uint256 => mapping(uint16 => uint256)) landData;

    function initialize (Promos _promos, CBKLandSale _cbkLandSale) public initializer {
        __ERC721_init("CryptoBladesKingdom Land", "CBKL");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        promos = _promos;
        cbkLandSale = _cbkLandSale;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    function get(uint256 id) public view returns (uint256, uint256, uint256, uint256) {
        return (landData[id][LT], landData[id][LC], landData[id][LX], landData[id][LY]);
    }

    // Function can have the skillshop purchase removed eventually to reduce contract size
    // false => it's a booked land
    // true => it's an actual land NFT
    function get(address owner) public view returns (uint256, uint256, uint256, uint256, bool) {
        if(balanceOf(owner) == 0){
            // Check if they have a shop purchase booked
            (uint8 tier, uint32 stamp) = cbkLandSale.getPurchaseOf(owner);

            if(tier == 1) { stamp = 0; /* Round robin stamp; not a chunk id */ }

            return (uint256(tier), uint256(stamp), 0, 0, false);
        }

        uint256 id = tokenOfOwnerByIndex(owner, 0);
        return (landData[id][LT], landData[id][LC], landData[id][LX], landData[id][LY], true);
    }

    // TODO: check no existing mint or skillshop booking
    // sanity checks on tier, chunkId, x and y
    function mint(address minter, uint8 tier, uint16 chunkId, uint256 x, uint256 y) public restricted {
        uint256 tokenID = landMinted++;
        
        landData[tokenID][LT] = tier;
        landData[tokenID][LC] = chunkId;
        landData[tokenID][LX] = x;
        landData[tokenID][LY] = y;
        
        _mint(minter, tokenID);
        promos.setBit(minter, promos.BIT_LAND_OWNED());

        emit LandMinted(minter, tokenID, tier, chunkId, x, y);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, to)) {
            require(!promos.getBit(to, promos.BIT_LAND_OWNED()), "Recv has purchased a land");
        }

        emit LandTransfered(from, to, tokenId);
        promos.setBit(to, promos.BIT_LAND_OWNED());
    }
}
