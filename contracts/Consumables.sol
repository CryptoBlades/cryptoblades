pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
//import "./cryptoblades.sol";

contract Consumables is Initializable, AccessControlUpgradeable {
    /* ========== CONSTANTS ========== */


    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event ConsumableGiven(address indexed owner);

    mapping(address => uint32) public owned;

    function initialize()
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier haveItem(address consumer) {
        _haveItem(consumer);
        _;
    }

    function _haveItem(address consumer) internal view {
        require(owned[consumer] > 0, "No item");
    }

    function giveItem(address buyer) public restricted {
        owned[buyer]++;
        emit ConsumableGiven(buyer);
    }

    function consumeItem() internal haveItem(msg.sender) {
        owned[msg.sender]--;
    }

    function getItemCount() public view returns (uint32) {
        return owned[msg.sender];
    }
}
