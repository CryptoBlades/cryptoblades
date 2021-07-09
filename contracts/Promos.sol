pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Promos is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize () public initializer {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(address => uint256) public bits;
    uint256 public constant BIT_FIRST_CHARACTER = 1;
    
    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function setBit(address user, uint256 bit) public restricted {
        bits[user] |= bit;
    }

    function unsetBit(address user, uint256 bit) public restricted {
        bits[user] &= ~bit;
    }

    function getBit(address user, uint256 bit) public view returns(bool) {
        return (bits[user] & bit) == bit;
    }

}