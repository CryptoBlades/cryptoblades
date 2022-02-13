pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./weapons.sol";
import "./SafeRandoms.sol";
import "./util.sol";

contract SpecialWeaponsManager is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant SPECIAL_WEAPON_SEED = keccak256("SPECIAL_WEAPON_SEED");

    // STATE
    Promos public promos;
    Weapons public weapons;
    SafeRandoms public safeRandoms;

    struct EventInfo {
        string name;
        uint8 weaponElement;
        uint256 endTime;
    }

    mapping(address => mapping(uint256 => uint256)) public userVars;
    uint256 public constant USERVAR_GENERAL_SHARD_SUPPLY = 1;
    mapping(address => mapping(uint256 => uint256)) public userEventShardSupply;
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_SHARD_COST_LOW = 1;
    uint256 public constant VAR_SHARD_COST_MEDIUM = 2;
    uint256 public constant VAR_SHARD_COST_HIGH = 3;
    uint256 public constant VAR_GENERAL_SHARD_COST_MULTIPLIER = 5;
    uint256 private eventCount;

    mapping(uint256 => EventInfo) public eventInfo;
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
            if(eventInfo[i].endTime > block.timestamp) {
                activeEventIds[i] = i;
            }
        }

        return activeEventIds;
    }

    function getActiveEventsCount() public view returns(uint256 activeEventsCount) {
        for(uint i = 1; i < eventCount; i++) {
            if(eventInfo[i].endTime > block.timestamp) {
                activeEventsCount++;
            }
        }
    }

    // FUNCTIONS

    function startNewEvent(string calldata name, uint8 element, uint256 period) external restricted {
        eventInfo[++eventCount] = EventInfo(
            name,
            element,
            block.timestamp + period
        );
    }

    function orderSpecialWeapon(uint256 eventId, uint256 orderOption) public {
        require(orderOption >= 1 && orderOption <= 3, "Invalid option");
        //require(userVars[msg.sender][USERVAR_SHARD_SUPPLY] >= vars[orderOption], "Not enough shards");
        require(userEventShardSupply[msg.sender][eventId] >= vars[orderOption], "Not enough shards");
        require(!getBit(msg.sender, eventId), "Limit 1");
        userEventShardSupply[msg.sender][eventId] -= vars[orderOption];
        setBit(msg.sender, eventId);
        userOrderOptionForEvent[msg.sender][eventId] = orderOption;
        safeRandoms.requestSingleSeed(msg.sender, getSeed(eventId));
    }

    function forgeSpecialWeapon(uint256 eventId) public {
        require(getBit(msg.sender, eventId) && userOrderOptionForEvent[msg.sender][eventId] > 0, 'Nothing to forge');
        userOrderOptionForEvent[msg.sender][eventId] = 0;
        mintSpecial(
            msg.sender,
            eventId,
            safeRandoms.popSingleSeed(msg.sender, getSeed(eventId), true, false),
            userOrderOptionForEvent[msg.sender][eventId],
            eventInfo[eventId].weaponElement
        );
    }

    function addShards(address user, uint256 eventId, uint256 shardsAmount) external restricted {
        if(getActiveEventIds().length > 0) {
            userEventShardSupply[user][eventId] += shardsAmount;
        }
        else {
            userVars[user][USERVAR_GENERAL_SHARD_SUPPLY] += shardsAmount.div(3);
        }
    }

    function mintSpecial(address minter, uint256 eventId, uint256 seed, uint256 orderOption, uint8 element) private returns(uint256) {
        uint256 stars;
        uint256 roll = seed % 100;
        if(orderOption == 3) {
            stars = 4;
        }
        else if(orderOption == 2) {
            if(roll < 16) {
                stars = 4;
            }
            else {
                stars = 3;
            }
        }
        else {
            if(roll < 5) {
                stars = 4;
            }
            else if (roll < 28) {
                stars = 3;
            }
            else {
                stars = 2;
            }
        }

        return mintSpecialWeaponWithStars(minter, eventId, stars, seed, element);
    }

    function mintSpecialWeaponWithStars(address minter, uint256 eventId, uint256 stars, uint256 seed, uint8 element) private returns(uint256) {
        return weapons.mintSpecialWeapon(minter, eventId, stars, seed, element);
    }

    function convertEventToGeneralShards(uint256 eventId, uint256 amount) external {
        require(userEventShardSupply[msg.sender][eventId] > amount, 'Not enough shards');
        userEventShardSupply[msg.sender][eventId] -= amount;
        uint256 convertedAmount = amount.div(3);
        convertedAmount += amount > convertedAmount.mul(3) ? 1 : 0;
        userVars[msg.sender][USERVAR_GENERAL_SHARD_SUPPLY] += convertedAmount;
    }

    function convertGeneralToEventShards(uint256 eventId, uint256 amount) external {
        require(userVars[msg.sender][USERVAR_GENERAL_SHARD_SUPPLY] > amount, 'Not enough shards');
        userVars[msg.sender][USERVAR_GENERAL_SHARD_SUPPLY] -= amount;
        uint256 convertedAmount = amount.div(3);
        convertedAmount += amount > convertedAmount.mul(3) ? 1 : 0;
        userEventShardSupply[msg.sender][eventId] += convertedAmount;
    }
}
