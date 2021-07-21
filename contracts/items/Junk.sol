pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract Junk is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize () public initializer {
        __ERC721_init("CryptoBlades Junk", "CBJ");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(uint256 => uint8) public stars;

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function mint(address minter, uint8 mintStars) public restricted returns(uint256) {

        uint256 tokenID = totalSupply();
        stars[tokenID] = mintStars;
        _mint(minter, tokenID);
        return tokenID;
    }

}