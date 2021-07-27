pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "../interfaces/IERC721MintAccessSeeded.sol";

contract KeyLootbox is Initializable, ERC721Upgradeable, AccessControlUpgradeable, IERC721MintAccessSeeded {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event MintAccessSeeded(address indexed minter, address indexed receiver, uint256 ref, uint256 indexed id);

    function initialize () public initializer {
        __ERC721_init("CryptoBlades Key Lootbox", "CBKBX");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function mint(address minter) public restricted returns(uint256) {

        uint256 tokenID = totalSupply();
        _mint(minter, tokenID);
        return tokenID;
    }

    function mintAccessSeeded(address receiver, uint256 ref, uint256 seed) external override restricted {
        uint tokenID = mint(receiver);
        emit MintAccessSeeded(msg.sender, receiver, ref, tokenID);
    }

}