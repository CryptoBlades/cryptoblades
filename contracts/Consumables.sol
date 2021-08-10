pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract Consumables is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event ConsumableGiven(address indexed owner, uint32 amount);

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

    modifier haveItem(uint32 amount) {
        require(owned[msg.sender] >= amount, "No item");
        _;
    }

    function giveItem(address buyer, uint32 amount) public restricted {
        owned[buyer] += amount;
        emit ConsumableGiven(buyer, amount);
    }

    function consumeItem(uint32 amount) internal haveItem(amount) itemNotDisabled {
        owned[msg.sender] -= amount;
    }

    function getItemCount() public view returns (uint32) {
        return owned[msg.sender];
    }

    function toggleItemCanUse(bool canUse) external isAdmin {
        _enabled = canUse;
    }

    function giveItemByAdmin(address receiver, uint32 amount) external isAdmin {
        owned[receiver] += amount;
    }

    function takeItemByAdmin(address target, uint32 amount) external isAdmin {
        require(owned[target] >= amount, 'Not enough item');
        owned[target] -= amount;
    }

    function itemEnabled() public view returns (bool){
        return _enabled;
    }
}