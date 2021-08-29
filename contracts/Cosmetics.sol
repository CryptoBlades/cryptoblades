pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract Cosmetics is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event CosmeticGiven(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticUsed(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticRestored(address indexed owner, uint32 cosmetic, uint32 amount);
    
    event CosmeticGivenByAdmin(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticTakenByAdmin(address indexed owner, uint32 cosmetic, uint32 amount);

    mapping(address => mapping(uint32 => uint32)) public owned;

    mapping(uint32 => bool) internal _cosmeticAvailable;

    uint32 internal constant _noCosmetic = 0;

    function initialize()
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier isAdmin() {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier cosmeticAvailable(uint32 cosmetic) {
         require(_cosmeticAvailable[cosmetic], "Not available");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier haveCosmetic(uint32 cosmetic, uint32 amount) {
        require(owned[msg.sender][cosmetic] >= amount, "No cosmetic");
        _;
    }

    function giveCosmetic(address buyer, uint32 cosmetic, uint32 amount) public restricted {
        owned[buyer][cosmetic] += amount;
        emit CosmeticGiven(buyer, cosmetic, amount);
    }

    function useCosmetic(uint32 cosmetic, uint32 amount) internal haveCosmetic(cosmetic, amount) cosmeticAvailable(cosmetic) {
        owned[msg.sender][cosmetic] -= amount;
        emit CosmeticUsed(msg.sender, cosmetic, amount);
    }

    function _restoreCosmetic(uint32 cosmetic, uint32 amount) internal {
        owned[msg.sender][cosmetic] += amount;
        emit CosmeticRestored(msg.sender, cosmetic, amount);
    }

    function getCosmeticCount(uint32 cosmetic) public view returns(uint32) {
        return owned[msg.sender][cosmetic];
    }

    function isCosmeticAvailable(uint32 cosmetic) public view returns (bool){
        return _cosmeticAvailable[cosmetic];
    }

    function toggleCosmeticAvailable(uint32 cosmetic, bool available) external isAdmin {
        _cosmeticAvailable[cosmetic] = available;
    }

    function giveCosmeticByAdmin(address receiver, uint32 cosmetic, uint32 amount) external isAdmin cosmeticAvailable(cosmetic) {
        owned[receiver][cosmetic] += amount;
        emit CosmeticGivenByAdmin(receiver, cosmetic, amount);
    }

    function takeCosmeticByAdmin(address target, uint32 cosmetic, uint32 amount) external isAdmin {
        require(owned[target][cosmetic] >= amount, 'Not enough cosmetic');
        owned[target][cosmetic] -= amount;
        emit CosmeticTakenByAdmin(target, cosmetic, amount);
    }
}