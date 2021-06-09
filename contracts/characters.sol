// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./util.sol";

contract Characters is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    //using SafeMath for uint16;
    //using SafeMath for uint8;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");

    function initialize () public initializer {
        __ERC721_init("CryptoBlades character", "CBC");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //TODO: This code was copy-pasted from here: https://forum.openzeppelin.com/t/derived-contract-must-override-function-supportsinterface/6315
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
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

    event NewCharacter(uint256 indexed character, address indexed minter);
    event LevelUp(address indexed owner, uint256 indexed character, uint16 level);

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function get(uint256 id) public view returns (uint16, uint8, uint8, uint64, uint16, uint16, uint16, uint16, uint16, uint16) {
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

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint16 limit) public pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function mint(address minter, uint256 seed) public restricted {
        uint256 tokenID = tokens.length;

        uint16 xp = 0;
        uint8 level = 0; // 1
        uint8 trait = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
        uint64 staminaTimestamp = uint64(block.timestamp - getStaminaMaxWait());

        tokens.push(Character(xp, level, trait, staminaTimestamp));
        cosmetics.push(CharacterCosmetics(0, RandomUtil.combineSeeds(seed, 1)));
        _mint(minter, tokenID);
        emit NewCharacter(tokenID, minter);
    }

    function getLevel(uint256 id) public view returns (uint8) {
        return tokens[id].level;
    }

    //TODO: Check Math...
    function getRequiredXpForNextLevel(uint8 currentLevel) public pure returns (uint16) {
        uint xp = 16;
        for(uint i = 0; i < currentLevel; i++) {
            if (xp <= 112)
            {
                xp = xp + (xp / 10);
            }
            else
            {
                xp = xp + (i - 14) + (1);
            }
        }
        return uint16(xp);
    }

    function getPower(uint256 id) public view returns (uint24) {
        return getPowerAtLevel(getLevel(id));
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
            //TODO: MATH!!!
            uint256(1000) + level* 10 * (level / 10 + 1)
        );
    }

    function getTrait(uint256 id) public view returns (uint8) {
        return tokens[id].trait;
    }

    function getXp(uint256 id) public view returns (uint32) {
        return tokens[id].xp;
    }

    function gainXp(uint256 id, uint16 xp) public restricted {
        Character storage char = tokens[id];
        if(char.level < 255) {
            uint newXp = char.xp + xp;
            uint requiredToLevel = getRequiredXpForNextLevel(char.level); // technically next level
            while(newXp >= requiredToLevel) {
                newXp = newXp - requiredToLevel;
                char.level = uint8(char.level + 1);
                emit LevelUp(ownerOf(id), id, char.level);
                requiredToLevel = getRequiredXpForNextLevel(char.level);
            }
            char.xp = uint16(newXp);
        }
    }

    function getStaminaTimestamp(uint256 id) public view returns (uint64) {
        return tokens[id].staminaTimestamp;
    }

    function setStaminaTimestamp(uint256 id, uint64 timestamp) public restricted {
        tokens[id].staminaTimestamp = timestamp;
    }

    function drainStamina(uint256 id, uint8 amount) public restricted returns(bool) {
        if(getStaminaPoints(id) >= amount) {
            uint64 drainTime = uint64(amount * secondsPerStamina);
            if(isStaminaFull(id)) { // if stamina full, we reset timestamp and drain from that
                setStaminaTimestamp(id, uint64(block.timestamp - (getStaminaMaxWait()) + (drainTime)));
            }
            else {
                //TODO: MATH
                setStaminaTimestamp(id, uint64(uint256(getStaminaTimestamp(id)) + drainTime));
            }
            return true;
        }
        else {
            return false;
        }
    }

    function getStaminaPoints(uint256 id) public view returns (uint8) {
        uint64 timestamp = getStaminaTimestamp(id);
        if(timestamp  > block.timestamp)
            return 0;
        //TODO: Math
        uint256 points = block.timestamp - (timestamp / secondsPerStamina);
        if(points > maxStamina) {
            points = maxStamina;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view returns (bool) {
        return getStaminaPoints(id) >= maxStamina;
    }

    function getStaminaMaxWait() public pure returns (uint64) {
        return uint64(maxStamina * (secondsPerStamina));
    }

    mapping(address => mapping(uint256 => uint256)) private ownerTokens;

    function tokenOfOwnerByIndex(address _owner, uint256 _index)  public view returns (uint tokenId){
        return ownerTokens[_owner][_index];
    }

    function _beforeTokenTransfer(address /* from */, address to, uint256 /* tokenId */) internal override {
        if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, to)) {
            require(balanceOf(to) < 4, "Recv has too many characters");
        }
    }
}
