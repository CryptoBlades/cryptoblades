pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./weapons.sol";
import "./SafeRandoms.sol";
import "./util.sol";

contract BurningManager is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant SPECIAL_WEAPON_SEED = keccak256("SPECIAL_WEAPON_SEED");

    // STATE
    Promos public promos;
    Weapons public weapons;
    SafeRandoms public safeRandoms;

    mapping(address => mapping(uint256 => uint256)) public userVars;
    uint256 public constant USERVAR_SHARD_SUPPLY = 1;
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_SHARD_COST_LOW = 1;
    uint256 public constant VAR_SHARD_COST_MEDIUM = 2;
    uint256 public constant VAR_SHARD_COST_HIGH = 3;
    uint256 public constant VAR_SHARD_COST_VERY_HIGH = 4;
    uint256 private eventCount;

    mapping(uint256 => uint256) public eventEndTime;
    mapping(address => uint256) public specialWeaponsBits;
    mapping(address => mapping(uint256 => uint256)) public userOrderOptionForEvent;


    function initialize(Promos _promos, Weapons _weapons, SafeRandoms _safeRandoms)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        promos = _promos;
        weapons = _weapons;
        safeRandoms = _safeRandoms;
        eventCount = 0;
    }

    // MODIFIERS

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    // BITS

    function setBit(address user, uint256 bit) internal {
        specialWeaponsBits[user] |= bit;
    }

    function getBit(address user, uint256 bit) internal view returns (bool) {
        return (specialWeaponsBits[user] & bit) == bit;
    }

    // VIEWS

    function getSeed(uint256 eventId) internal pure returns(uint256 seed) {
        seed = uint(keccak256(abi.encodePacked(SPECIAL_WEAPON_SEED, uint(1), eventId)));
    }

    function getActiveEventIds() public view returns(uint256[] memory) {
        uint256[] memory activeEventIds = new uint256[](getActiveEventsCount());
        for(uint i = 1; i < eventCount; i++) {
            if(eventEndTime[i] > block.timestamp) {
                activeEventIds[i] = i;
            }
        }

        return activeEventIds;
    }

    function getActiveEventsCount() public view returns(uint256 activeEventsCount) {
        for(uint i = 1; i < eventCount; i++) {
            if(eventEndTime[i] > block.timestamp) {
                activeEventsCount++;
            }
        }
    }

    // FUNCTIONS

    function startNewEvent(uint256 period) external restricted {
        eventEndTime[++eventCount] = block.timestamp + period;
    }

    function orderSpecialWeapon(uint256 eventId, uint256 orderOption) public {
        require(orderOption >= 1 && orderOption <= 4, "Invalid option");
        require(userVars[msg.sender][USERVAR_SHARD_SUPPLY] >= vars[orderOption], "Not enough shards");
        require(!getBit(msg.sender, eventId), "Limit 1");
        userVars[msg.sender][USERVAR_SHARD_SUPPLY] -= vars[orderOption];
        setBit(msg.sender, eventId);
        userOrderOptionForEvent[msg.sender][eventId] = orderOption;
        safeRandoms.requestSingleSeed(msg.sender, getSeed(eventId));
    }

    function forgeSpecialWeapon(uint256 eventId) public {
        require(getBit(msg.sender, eventId) && userOrderOptionForEvent[msg.sender][eventId] > 0, 'Nothing to forge');
        userOrderOptionForEvent[msg.sender][eventId] = 0;
        weapons.mintSpecial(msg.sender, safeRandoms.popSingleSeed(msg.sender, getSeed(eventId), true, false), userOrderOptionForEvent[msg.sender][eventId]);
    }

    function addShards(address user, uint256 shardsAmount) external restricted {
        if(getActiveEventIds().length > 0) {
            userVars[user][USERVAR_SHARD_SUPPLY] += shardsAmount;
        }
    }
}
