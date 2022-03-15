pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./weapons.sol";
import "./SafeRandoms.sol";
import "./util.sol";
import "./staking/StakingRewardsUpgradeable.sol";
import "./interfaces/IPriceOracle.sol";

contract SpecialWeaponsManager is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SPECIAL_WEAPON_SEED = keccak256("SPECIAL_WEAPON_SEED");

    // STATE
    Promos public promos;
    Weapons public weapons;
    SafeRandoms public safeRandoms;
    CryptoBlades public game;
    IPriceOracle public priceOracleSkillPerUsd;

    struct EventInfo {
        string name;
        uint8 weaponElement;
        uint256 endTime;
        uint256 supply;
        uint256 orderedCount;
    }

    mapping(address => mapping(uint256 => uint256)) public userEventShardSupply;
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_SHARD_COST_LOW = 1;
    uint256 public constant VAR_SHARD_COST_MEDIUM = 2;
    uint256 public constant VAR_SHARD_COST_HIGH = 3;
    uint256 public constant VAR_SKILL_USD_COST_LOW = 4;
    uint256 public constant VAR_SKILL_USD_COST_MEDIUM = 5;
    uint256 public constant VAR_SKILL_USD_COST_HIGH = 6;
    uint256 public constant VAR_CONVERT_RATIO_DENOMINATOR = 10;
    uint256 public constant VAR_DAILY_SHARDS_PER_SKILL_STAKED = 11;
    uint256 public eventCount;

    mapping(uint256 => EventInfo) public eventInfo;
    mapping(address => mapping(uint256 => bool)) public userForgedAtEvent;
    mapping(address => mapping(uint256 => uint256)) public userOrderOptionForEvent;
    mapping(address => uint256) userStakedSkill;
    mapping(address => uint256) userStakedSkillUpdatedTimestamp;
    mapping(address => uint256) userSkillStakingShardsRewards;


    function initialize(Promos _promos, Weapons _weapons, SafeRandoms _safeRandoms, CryptoBlades _game, IPriceOracle _priceOracleSkillPerUsd)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        promos = _promos;
        weapons = _weapons;
        safeRandoms = _safeRandoms;
        game = _game;
        priceOracleSkillPerUsd = _priceOracleSkillPerUsd;
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

    modifier isValidOption(uint256 orderOption) {
        _isValidOption(orderOption);
        _;
    }

    function _isValidOption(uint256 orderOption) internal pure {
        require(orderOption >= 1 && orderOption <= 3, "Invalid option");
    }

    modifier isEventActive(uint256 eventId) {
        _isEventActive(eventId);
        _;
    }

    function _isEventActive(uint256 eventId) internal view {
        require(getIsEventActive(eventId), "Event inactive");
    }

    modifier canBeOrdered(uint256 eventId) {
        _canBeOrdered(eventId);
        _;
    }

    function _canBeOrdered(uint256 eventId) internal view {
        require(userOrderOptionForEvent[msg.sender][eventId] == 0, "Limit 1");
        require(hasRemainingSupply(eventId), "Sold out");
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

    function hasRemainingSupply(uint256 eventId) public view returns(bool) {
        return eventInfo[eventId].supply == 0 || eventInfo[eventId].orderedCount < eventInfo[eventId].supply;
    }

    function getTotalOrderedCount(uint256 eventId) public view returns(uint256) {
        return eventInfo[eventId].orderedCount;
    }

    function getEventInfo(uint256 eventId) public view returns(string memory, uint8, uint256, uint256, uint256) {
        EventInfo memory info = eventInfo[eventId];
        return (info.name, info.weaponElement, info.endTime, info.supply, info.orderedCount);
    }

    function getUserSpecialShardsSupply(address user, uint256 eventId) public view returns(uint256) {
        return userEventShardSupply[user][eventId];
    }

    function getUserShardsRewards(address user) public view returns(uint256) {
        return userSkillStakingShardsRewards[user]
            .add(userStakedSkill[user]
                .mul(vars[VAR_DAILY_SHARDS_PER_SKILL_STAKED])
                .mul(block.timestamp - userStakedSkillUpdatedTimestamp[user])
                .div(60 * 60 * 24)
                .div(1e18)
            );
    }

    function getSkillForgeCost(uint256 orderOption) public view returns(uint256) {
        return usdToSkill(ABDKMath64x64.divu(vars[orderOption + 3], 1));
    }

    function usdToSkill(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleSkillPerUsd.currentPrice());
    }

    // FUNCTIONS

    // supply 0 = unlimited
    function startNewEvent(string calldata name, uint8 element, uint256 period, uint256 supply) external restricted {
        eventInfo[++eventCount] = EventInfo(
            name,
            element,
            block.timestamp + period,
            supply,
            0
        );
    }

    function incrementEventCount() external restricted {
        eventCount++;
    }

    function updateStakingReward(address user, uint256 stakingAmount) external restricted {
        userSkillStakingShardsRewards[user] = getUserShardsRewards(user);
        userStakedSkill[user] = stakingAmount;
        userStakedSkillUpdatedTimestamp[user] = block.timestamp;
    }

    function claimShardRewards(uint256 eventId, uint256 amount) external {
        require(amount.mul(1e18) <= getUserShardsRewards(msg.sender), "Not enough rewards");
        userSkillStakingShardsRewards[msg.sender] = getUserShardsRewards(msg.sender).sub(amount.mul(1e18));
        userStakedSkillUpdatedTimestamp[msg.sender] = block.timestamp;
        userEventShardSupply[msg.sender][eventId] += amount;
    }

    function orderSpecialWeaponWithShards(uint256 eventId, uint256 orderOption) public canBeOrdered(eventId) isEventActive(eventId) isValidOption(orderOption) {
        require(userEventShardSupply[msg.sender][eventId] >= vars[orderOption], "Not enough shards");
        userEventShardSupply[msg.sender][eventId] -= vars[orderOption];
        userOrderOptionForEvent[msg.sender][eventId] = orderOption;
        eventInfo[eventId].orderedCount++;
        safeRandoms.requestSingleSeed(msg.sender, getSeed(eventId));
    }

    function orderSpecialWeaponWithSkill(uint256 eventId, uint256 orderOption) public canBeOrdered(eventId) isEventActive(eventId) isValidOption(orderOption) {
        game.payContractTokenOnly(msg.sender, getSkillForgeCost(orderOption));
        userOrderOptionForEvent[msg.sender][eventId] = orderOption;
        eventInfo[eventId].orderedCount++;
        safeRandoms.requestSingleSeed(msg.sender, getSeed(eventId));
    }

    function forgeSpecialWeapon(uint256 eventId) public {
        require(userOrderOptionForEvent[msg.sender][eventId] > 0, 'Nothing to forge');
        require(!userForgedAtEvent[msg.sender][eventId], 'Already forged');
        userForgedAtEvent[msg.sender][eventId] = true;
        mintSpecial(
            msg.sender,
            eventId,
            safeRandoms.popSingleSeed(msg.sender, getSeed(eventId), true, false),
            userOrderOptionForEvent[msg.sender][eventId],
            eventInfo[eventId].weaponElement
        );
    }

    function addShards(address user, uint256 eventId, uint256 shardsAmount) external restricted isEventActive(eventId){
        userEventShardSupply[user][eventId] += shardsAmount;
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

    function convertShards(uint256 eventIdFrom, uint256 eventIdTo, uint256 amount) external isEventActive(eventIdTo) {
        require(userEventShardSupply[msg.sender][eventIdFrom] >= amount, 'Not enough shards');
        userEventShardSupply[msg.sender][eventIdFrom] -= amount;
        uint256 convertedAmount = amount.div(vars[VAR_CONVERT_RATIO_DENOMINATOR]);
        convertedAmount += userEventShardSupply[msg.sender][eventIdFrom] == 0 && amount % vars[VAR_CONVERT_RATIO_DENOMINATOR] > 0 ? 1 : 0;
        userEventShardSupply[msg.sender][eventIdTo] += convertedAmount;
    }

    function updateEventEndTime(uint256 eventId, uint256 endTime) external restricted {
        eventInfo[eventId].endTime = endTime;
    }

    // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
    function privatePartnerOrder(address[] calldata receivers, uint256 eventId, uint256 orderOption) external isValidOption(orderOption) isEventActive(eventId) {
        require(hasRole(MINTER_ROLE, msg.sender), "Not minter");
        require(eventInfo[eventId].supply == 0 || receivers.length + eventInfo[eventId].orderedCount <= eventInfo[eventId].supply, "Not enough supply");
        for(uint i = 0; i < receivers.length; i++) {
            if(userOrderOptionForEvent[receivers[i]][eventId] != 0) continue;
            userOrderOptionForEvent[receivers[i]][eventId] = orderOption;
            eventInfo[eventId].orderedCount++;
            safeRandoms.requestSingleSeed(receivers[i], getSeed(eventId));
        }
    }

    // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
    function privatePartnerMint(address[] calldata receivers, uint256 eventId, uint256 orderOption) external isValidOption(orderOption) isEventActive(eventId) {
        require(hasRole(MINTER_ROLE, msg.sender), "Not minter");
        require(eventInfo[eventId].supply == 0 || receivers.length + eventInfo[eventId].orderedCount <= eventInfo[eventId].supply, "Not enough supply");
        for(uint i = 0; i < receivers.length; i++) {
            if(userOrderOptionForEvent[receivers[i]][eventId] != 0 || userForgedAtEvent[receivers[i]][eventId]) continue;
            userOrderOptionForEvent[receivers[i]][eventId] = orderOption;
            eventInfo[eventId].orderedCount++;
            userForgedAtEvent[receivers[i]][eventId] = true;
            mintSpecial(
                receivers[i],
                eventId,
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), receivers[i]))),
                userOrderOptionForEvent[receivers[i]][eventId],
                eventInfo[eventId].weaponElement
            );
        }
    }
}
