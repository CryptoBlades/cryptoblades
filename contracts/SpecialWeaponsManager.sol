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

    // id 0 = general shards supply
    mapping(address => mapping(uint256 => uint256)) public userEventShardSupply;
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_SHARD_COST_LOW = 1;
    uint256 public constant VAR_SHARD_COST_MEDIUM = 2;
    uint256 public constant VAR_SHARD_COST_HIGH = 3;
    uint256 public constant VAR_CONVERT_RATIO_DENOMINATOR = 5;
    uint256 public eventCount;

    mapping(uint256 => EventInfo) public eventInfo;
    mapping(address => mapping(uint256 => bool)) public userForgedAtEvent;
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

    // VARS

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    // VIEWS

    function getSeed(uint256 eventId) internal pure returns(uint256 seed) {
        seed = uint(keccak256(abi.encodePacked(SPECIAL_WEAPON_SEED, uint(1), eventId)));
    }

    function getActiveEventsIds() public view returns(uint256[] memory) {
        uint256[] memory activeEventIds = new uint256[](getActiveEventsCount());
        uint256 arrayIterator = 0;
        for(uint i = 1; i <= eventCount; i++) {
            if(eventInfo[i].endTime > block.timestamp) {
                activeEventIds[arrayIterator++] = i;
            }
        }

        return activeEventIds;
    }

    function getActiveEventsCount() public view returns(uint256 activeEventsCount) {
        for(uint i = 0; i <= eventCount; i++) {
            if(getIsEventActive(i)) {
                activeEventsCount++;
            }
        }
    }

    function getIsEventActive(uint256 eventId) public view returns(bool) {
        return eventInfo[eventId].endTime > block.timestamp;
    }

    function getEventInfo(uint256 eventId) public view returns(string memory, uint8, uint256) {
        EventInfo memory info = eventInfo[eventId];
        return (info.name, info.weaponElement, info.endTime);
    }

    function getUserSpecialShardsSupply(address user, uint256 eventId) public view returns(uint256) {
        return userEventShardSupply[user][eventId];
    }

    function getUserGeneralShardsSupply(address user) public view returns(uint256) {
        return userEventShardSupply[user][0];
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
        require(userEventShardSupply[msg.sender][eventId] >= vars[orderOption], "Not enough shards");
        require(userOrderOptionForEvent[msg.sender][eventId] == 0, "Limit 1");
        require(getIsEventActive(eventId), "Event inactive");
        userEventShardSupply[msg.sender][eventId] -= vars[orderOption];
        userOrderOptionForEvent[msg.sender][eventId] = orderOption;
        safeRandoms.requestSingleSeed(msg.sender, getSeed(eventId));
    }

    function orderSpecialWeaponWithGeneralShards(uint256 eventId, uint256 orderOption) public {
        require(orderOption >= 1 && orderOption <= 3, "Invalid option");
        require(userEventShardSupply[msg.sender][0] >= vars[orderOption].mul(vars[VAR_CONVERT_RATIO_DENOMINATOR]), "Not enough shards");
        require(userOrderOptionForEvent[msg.sender][eventId] == 0, "Limit 1");
        require(getIsEventActive(eventId), "Event inactive");
        userEventShardSupply[msg.sender][0] -= vars[orderOption].mul(vars[VAR_CONVERT_RATIO_DENOMINATOR]);
        userOrderOptionForEvent[msg.sender][eventId] = orderOption;
        safeRandoms.requestSingleSeed(msg.sender, getSeed(eventId));
    }

    function forgeSpecialWeapon(uint256 eventId) public {
        require(userOrderOptionForEvent[msg.sender][eventId] > 0, 'Nothing to forge');
        require(!userForgedAtEvent[msg.sender][eventId], 'Already forged');
        mintSpecial(
            msg.sender,
            eventId,
            safeRandoms.popSingleSeed(msg.sender, getSeed(eventId), true, false),
            userOrderOptionForEvent[msg.sender][eventId],
            eventInfo[eventId].weaponElement
        );
        userForgedAtEvent[msg.sender][eventId] = true;
    }

    function addShards(address user, uint256 eventId, uint256 shardsAmount) external restricted {
        if(getActiveEventsCount() > 0 && eventId != 0) {
            require(getIsEventActive(eventId), "Event inactive");
            userEventShardSupply[user][eventId] += shardsAmount;
        }
        else {
            userEventShardSupply[user][0] += shardsAmount;
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

    function convertShards(uint256 eventIdFrom, uint256 eventIdTo, uint256 amount) external {
        require(userEventShardSupply[msg.sender][eventIdFrom] > amount, 'Not enough shards');
        require(eventIdTo != 0 && !getIsEventActive(eventIdTo), 'Target event inactive');
        userEventShardSupply[msg.sender][eventIdFrom] -= amount;
        uint256 convertedAmount = amount.div(vars[VAR_CONVERT_RATIO_DENOMINATOR]);
        convertedAmount += amount % vars[VAR_CONVERT_RATIO_DENOMINATOR] > 0 ? 1 : 0;
        userEventShardSupply[msg.sender][eventIdTo] += convertedAmount;
    }

    function updateEventEndTime(uint256 eventId, uint256 endTime) external restricted {
        eventInfo[eventId].endTime = endTime;
    }
}
