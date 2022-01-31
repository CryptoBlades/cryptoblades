pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./weapons.sol";


contract BurningManager is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    // STATE
    Promos public promos;
    Weapons public weapons;

    mapping(address => mapping(uint256 => uint256)) public userVars;
    uint256 public constant USERVAR_SHARD_SUPPLY = 1;
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_SHARD_COST = 1;
    uint256 private specialEventCount;

    mapping(uint256 => uint256) public eventEndTime;
    mapping(address => uint256) public specialWeaponsBits;


    function initialize(Promos _promos, Weapons _weapons)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        promos = _promos;
        weapons = _weapons;
        specialEventCount = 0;
    }

    // MODIFIERS

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    // FUNCTIONS

    function setBit(address user, uint256 bit) external restricted {
        specialWeaponsBits[user] |= bit;
    }

    function startNewEvent(uint256 period) external restricted {
        eventEndTime[specialEventCount++] = block.timestamp + period;
    }

    function mintSpecialWeapon(uint256 eventId) public {
        require(userVars[msg.sender][USERVAR_SHARD_SUPPLY] > vars[VAR_SHARD_COST], 'Not enough shards');
        userVars[msg.sender][USERVAR_SHARD_SUPPLY] -= vars[VAR_SHARD_COST];
        specialWeaponsBits[msg.sender] |= eventId;
        weapons.mintSpecial(msg.snder, seed);
    }


}