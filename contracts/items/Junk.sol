pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "../Promos.sol";

contract Junk is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize (Promos _promos) public initializer {
        __ERC721_init("CryptoBlades Junk", "CBJ");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        promos = _promos;
    }

    Promos public promos;

    mapping(uint256 => uint8) public tokenStars;

    event Minted(uint256 indexed id, address indexed minter);
    event Burned(uint256 indexed id, address indexed burner);

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function get(uint256 id) public view
        returns (
            uint8 _stars
    ) {
        _stars = tokenStars[id];
    }

    function getOwned() public view returns(uint256[] memory) {
        return getOwnedBy(msg.sender);
    }

    function getOwnedBy(address owner) public view returns(uint256[] memory tokens) {
        tokens = new uint256[](balanceOf(owner));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    function getStars(uint256[] memory ids) public restricted view returns (uint8[] memory stars) {
        stars = new uint8[](ids.length);
        for(uint256 i = 0; i < ids.length; i++) {
            stars[i] = tokenStars[ids[i]];
        }
    }

    function mint(address minter, uint8 mintStars) public restricted returns(uint256 tokenID) {
        tokenID = totalSupply();
        tokenStars[tokenID] = mintStars;
        _mint(minter, tokenID);
        emit Minted(tokenID, minter);
    }

    function mintN(address minter, uint8 mintStars, uint32 amount) public restricted returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](amount);
        for(uint i = 0; i < amount; i++) {
            tokenIds[i] = mint(minter, mintStars);
        }
    }

    function burn(uint256 tokenID) public restricted {
        address burner = ownerOf(tokenID);
        _burn(tokenID);
        delete tokenStars[tokenID];
        emit Burned(tokenID, burner);
    }

    function burn(uint256[] memory tokenIDs) public restricted {
        for(uint i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(promos.getBit(from, 4) == false && promos.getBit(to, 4) == false);
    }

}
