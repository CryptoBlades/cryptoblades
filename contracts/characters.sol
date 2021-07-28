pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./util.sol";
import "./interfaces/ITransferCooldownable.sol";

contract Characters is Initializable, ERC721Upgradeable, AccessControlUpgradeable, ITransferCooldownable {

    using SafeMath for uint16;
    using SafeMath for uint8;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");
    bytes32 public constant RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP = keccak256("RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP");

    uint256 public constant TRANSFER_COOLDOWN = 1 days;

    function initialize () public initializer {
        __ERC721_init("CryptoBlades character", "CBC");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_1ee400a() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        experienceTable = [
            16, 17, 18, 19, 20, 22, 24, 26, 28, 30, 33, 36, 39, 42, 46, 50, 55, 60, 66
            , 72, 79, 86, 94, 103, 113, 124, 136, 149, 163, 178, 194, 211, 229, 248, 268
            , 289, 311, 334, 358, 383, 409, 436, 464, 493, 523, 554, 586, 619, 653, 688
            , 724, 761, 799, 838, 878, 919, 961, 1004, 1048, 1093, 1139, 1186, 1234, 1283
            , 1333, 1384, 1436, 1489, 1543, 1598, 1654, 1711, 1769, 1828, 1888, 1949, 2011
            , 2074, 2138, 2203, 2269, 2336, 2404, 2473, 2543, 2614, 2686, 2759, 2833, 2908
            , 2984, 3061, 3139, 3218, 3298, 3379, 3461, 3544, 3628, 3713, 3799, 3886, 3974
            , 4063, 4153, 4244, 4336, 4429, 4523, 4618, 4714, 4811, 4909, 5008, 5108, 5209
            , 5311, 5414, 5518, 5623, 5729, 5836, 5944, 6053, 6163, 6274, 6386, 6499, 6613
            , 6728, 6844, 6961, 7079, 7198, 7318, 7439, 7561, 7684, 7808, 7933, 8059, 8186
            , 8314, 8443, 8573, 8704, 8836, 8969, 9103, 9238, 9374, 9511, 9649, 9788, 9928
            , 10069, 10211, 10354, 10498, 10643, 10789, 10936, 11084, 11233, 11383, 11534
            , 11686, 11839, 11993, 12148, 12304, 12461, 12619, 12778, 12938, 13099, 13261
            , 13424, 13588, 13753, 13919, 14086, 14254, 14423, 14593, 14764, 14936, 15109
            , 15283, 15458, 15634, 15811, 15989, 16168, 16348, 16529, 16711, 16894, 17078
            , 17263, 17449, 17636, 17824, 18013, 18203, 18394, 18586, 18779, 18973, 19168
            , 19364, 19561, 19759, 19958, 20158, 20359, 20561, 20764, 20968, 21173, 21379
            , 21586, 21794, 22003, 22213, 22424, 22636, 22849, 23063, 23278, 23494, 23711
            , 23929, 24148, 24368, 24589, 24811, 25034, 25258, 25483, 25709, 25936, 26164
            , 26393, 26623, 26854, 27086, 27319, 27553, 27788, 28024, 28261, 28499, 28738
            , 28978
        ];
    }

    function migrateTo_951a020() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        _registerInterface(TransferCooldownableInterfaceId.interfaceId());
    }

    function migrateTo_ef994e2(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        promos = _promos;
    }

    function migrateTo_b627f23() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        characterLimit = 4;
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-256
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
    */

    struct Character {
        uint16 xp; // xp to next level
        uint8 level; // up to 256 cap
        uint8 trait; // 2b trait, TBD
        uint64 staminaTimestamp; // standard timestamp in seconds-resolution marking regen start from 0
    }
    struct CharacterCosmetics {
        uint8 version;
        uint256 seed;
    }

    Character[] private tokens;
    CharacterCosmetics[] private cosmetics;

    uint256 public constant maxStamina = 200;
    uint256 public constant secondsPerStamina = 300; //5 * 60

    uint256[256] private experienceTable; // fastest lookup in the west

    mapping(uint256 => uint256) public override lastTransferTimestamp;

    Promos public promos;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    uint256 public characterLimit;

    event NewCharacter(uint256 indexed character, address indexed minter);
    event LevelUp(address indexed owner, uint256 indexed character, uint16 level);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }

    function transferCooldownEnd(uint256 tokenId) public override view returns (uint256) {
        return lastTransferTimestamp[tokenId].add(TRANSFER_COOLDOWN);
    }

    function transferCooldownLeft(uint256 tokenId) public override view returns (uint256) {
        (bool success, uint256 secondsLeft) =
            lastTransferTimestamp[tokenId].trySub(
                block.timestamp.sub(TRANSFER_COOLDOWN)
            );

        return success ? secondsLeft : 0;
    }

    function get(uint256 id) public view noFreshLookup(id) returns (uint16, uint8, uint8, uint64, uint16, uint16, uint16, uint16, uint16, uint16) {
        Character memory c = tokens[id];
        CharacterCosmetics memory cc = cosmetics[id];
        return (c.xp, c.level, c.trait, c.staminaTimestamp,
            getRandomCosmetic(cc.seed, 1, 13), // head
            getRandomCosmetic(cc.seed, 2, 45), // arms
            getRandomCosmetic(cc.seed, 3, 61), // torso
            getRandomCosmetic(cc.seed, 4, 41), // legs
            getRandomCosmetic(cc.seed, 5, 22), // boots
            getRandomCosmetic(cc.seed, 6, 2) // race
        );
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint16 limit) private pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function mint(address minter, uint256 seed) public restricted {
        uint256 tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        uint16 xp = 0;
        uint8 level = 0; // 1
        uint8 trait = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
        uint64 staminaTimestamp = uint64(now.sub(getStaminaMaxWait()));

        tokens.push(Character(xp, level, trait, staminaTimestamp));
        cosmetics.push(CharacterCosmetics(0, RandomUtil.combineSeeds(seed, 1)));
        _mint(minter, tokenID);
        emit NewCharacter(tokenID, minter);
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].level; // this is used by dataminers and it benefits us
    }

    function getRequiredXpForNextLevel(uint8 currentLevel) public view returns (uint16) {
        return uint16(experienceTable[currentLevel]); // this is helpful to users as the array is private
    }

    function getPower(uint256 id) public view noFreshLookup(id) returns (uint24) {
        return getPowerAtLevel(tokens[id].level);
    }

    function getPowerAtLevel(uint8 level) public pure returns (uint24) {
        // does not use fixed points since the numbers are simple
        // the breakpoints every 10 levels are floored as expected
        // level starts at 0 (visually 1)
        // 1000 at lvl 1
        // 9000 at lvl 51 (~3months)
        // 22440 at lvl 105 (~3 years)
        // 92300 at lvl 255 (heat death of the universe)
        return uint24(
            uint256(1000)
                .add(level.mul(10))
                .mul(level.div(10).add(1))
        );
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].trait;
    }

    function getXp(uint256 id) public view noFreshLookup(id) returns (uint32) {
        return tokens[id].xp;
    }

    function gainXp(uint256 id, uint16 xp) public restricted {
        Character storage char = tokens[id];
        if(char.level < 255) {
            uint newXp = char.xp.add(xp);
            uint requiredToLevel = experienceTable[char.level]; // technically next level
            while(newXp >= requiredToLevel) {
                newXp = newXp - requiredToLevel;
                char.level += 1;
                emit LevelUp(ownerOf(id), id, char.level);
                if(char.level < 255)
                    requiredToLevel = experienceTable[char.level];
                else
                    newXp = 0;
            }
            char.xp = uint16(newXp);
        }
    }

    function getStaminaTimestamp(uint256 id) public view noFreshLookup(id) returns (uint64) {
        return tokens[id].staminaTimestamp;
    }

    function setStaminaTimestamp(uint256 id, uint64 timestamp) public restricted {
        tokens[id].staminaTimestamp = timestamp;
    }

    function getStaminaPoints(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStaminaPointsFromTimestamp(tokens[id].staminaTimestamp);
    }

    function getStaminaPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerStamina;
        if(points > maxStamina) {
            points = maxStamina;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view noFreshLookup(id) returns (bool) {
        return getStaminaPoints(id) >= maxStamina;
    }

    function getStaminaMaxWait() public pure returns (uint64) {
        return uint64(maxStamina * secondsPerStamina);
    }

    function getFightDataAndDrainStamina(uint256 id, uint8 amount) public restricted returns(uint96) {
        Character storage char = tokens[id];
        uint8 staminaPoints = getStaminaPointsFromTimestamp(char.staminaTimestamp);
        require(staminaPoints >= amount, "Not enough stamina!");

        uint64 drainTime = uint64(amount * secondsPerStamina);
        uint64 preTimestamp = char.staminaTimestamp;
        if(staminaPoints >= maxStamina) { // if stamina full, we reset timestamp and drain from that
            char.staminaTimestamp = uint64(now - getStaminaMaxWait() + drainTime);
        }
        else {
            char.staminaTimestamp = uint64(char.staminaTimestamp + drainTime);
        }
        // bitwise magic to avoid stacking limitations later on
        return uint96(char.trait | (getPowerAtLevel(char.level) << 8) | (preTimestamp << 32));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, to)) {
            require(balanceOf(to) < characterLimit, "Recv has too many characters");
        }

        // when not minting or burning...
        if(from != address(0) && to != address(0)) {
            // only allow transferring a particular token every TRANSFER_COOLDOWN seconds
            require(lastTransferTimestamp[tokenId] < block.timestamp.sub(TRANSFER_COOLDOWN), "Transfer cooldown");

            if(!hasRole(RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP, to)) {
                lastTransferTimestamp[tokenId] = block.timestamp;
            }
        }

        promos.setBit(from, promos.BIT_FIRST_CHARACTER());
        promos.setBit(to, promos.BIT_FIRST_CHARACTER());
    }

    function setCharacterLimit(uint256 max) public restricted {
        characterLimit = max;
    }
}
