pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract Consumables is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event ConsumableGiven(address indexed owner);

    mapping(address => uint32) public owned;
    
    bool internal _enabled;

    function initialize()
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;
    }

    modifier isAdmin() {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier itemNotDisabled() {
         require(_enabled, "Item disabled");
        _;
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

    function consumeItem() internal haveItem(msg.sender) itemNotDisabled {
        owned[msg.sender]--;
    }

    function getItemCount() public view returns (uint32) {
        return owned[msg.sender];
    }

    function toggleItemCanUse(bool canUse) public isAdmin {
        _enabled = canUse;
    }

    function giveItem(address receiver, uint32 amount) public isAdmin {
        require(amount > 0, 'Amount negative');
        owned[receiver] += amount;
    }

    function takeItem(address target, uint32 amount) public isAdmin {
        require(amount > 0, 'Amount negative');
        require(owned[target] >= amount, 'Not enough item');
        owned[target] -= amount;
    }

    function itemEnabled() public view returns (bool){
        return _enabled;
    }
}
