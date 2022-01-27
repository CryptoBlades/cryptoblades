pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "../Promos.sol";
import "../util.sol";

contract RaidTrinket is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize (Promos _promos) public initializer {
        __ERC721_init("CryptoBlades Trinket", "CBRT");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        promos = _promos;
    }

    Promos public promos;

    mapping(uint256 => uint8) public tokenStars;
    mapping(uint256 => uint256) public tokenEffect;

    event Minted(uint256 indexed id, address indexed minter);
    event Burned(uint256 indexed id, address indexed burner);

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function get(uint256 id) public view
        returns (
            uint8 _stars, uint256 _effect
    ) {
        _stars = tokenStars[id];
        _effect = tokenEffect[id];
    }

    function getOwned() public view returns(uint256[] memory) {
        return getOwnedBy(msg.sender);
    }

    function getOwnedBy(address owner) public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(owner));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    function getStars(uint256 id) public view returns (uint8) {
        return tokenStars[id];
    }

    function getStars(uint256[] memory ids) public view restricted returns (uint8[] memory) {
        uint8[] memory stars = new uint8[](ids.length);
        for(uint256 i = 0; i < ids.length; i++) {
            stars[i] = tokenStars[ids[i]];
        }
        return stars;
    }

    function mint(address minter, uint8 mintStars, uint256 mintEffect) public restricted returns(uint256) {
        uint256 tokenID = totalSupply();
        tokenStars[tokenID] = mintStars;
        tokenEffect[tokenID] = mintEffect;
        _mint(minter, tokenID);
        emit Minted(tokenID, minter);
        return tokenID;
    }

    //TODO: check how to handle mintEffects
    function batchMint(address minter, uint8 mintStars, uint32 amount) public restricted returns(uint256[] memory) {
        uint256[] memory tokenIDs = new uint256[](amount);
        for(uint256 i = 0; i < amount; i++) {
            tokenIDs[i] = mint(minter, mintStars, 0);
        }
        return tokenIDs;
    }

    function burn(uint256 tokenID) public restricted {
        address burner = ownerOf(tokenID);
        _burn(tokenID);
        delete tokenStars[tokenID];
        delete tokenEffect[tokenID];
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
