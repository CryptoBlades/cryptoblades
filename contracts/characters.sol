pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";


contract Characters is Initializable, ERC721Upgradeable, OwnableUpgradeable {

    address private main;

    function initialize () public initializer {
        __ERC721_init("CryptoBlades character", "CBC");
        __Ownable_init_unchained();
        main = address(0);
    }

    function setMain(address newMain) external onlyOwner {
        main = newMain;
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

    Character[] private tokens;

    uint256 public constant maxStamina = 200;
    uint256 public constant secondsPerStamina = 300; //5 * 60

    event NewCharacter(uint256 indexed character, address indexed minter);
    event LevelUp(uint256 indexed character, uint16 level);

    modifier restricted() {
        //require(main == msg.sender, "Can only be called by main file");
        // todo proper with accessControl
        _;
    }

    function get(uint256 id) public view returns (uint16, uint8, uint8, uint64, uint16, uint16, uint16, uint16, uint16, uint16) {
        Character memory c = tokens[id];
        uint appearance = RandomUtil.randomSeeded(id);
        return (c.xp, c.level, c.trait, c.staminaTimestamp,
            // feel free to change this but beware of stack limits
            uint16(appearance % 256), // head
            uint16((appearance / 64) % 256), // arms
            uint16((appearance / 4096) % 256), // torso
            uint16((appearance / 262144) % 256), // legs
            uint16((appearance / 16777216) % 256), // boots
            uint16((appearance / 1073741824) % 256) // race
        );
    }

    function mint(address minter, uint256 seed) public restricted {
        uint256 tokenID = tokens.length;

        uint16 xp = 0;
        uint8 level = 0; // 1
        uint8 trait = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
        uint64 staminaTimestamp = uint64(now - getStaminaMaxWait());

        tokens.push(Character(xp, level, trait, staminaTimestamp));
        _mint(minter, tokenID);
        emit NewCharacter(tokenID, minter);
    }

    function getLevel(uint256 id) public view returns (uint8) {
        return tokens[id].level;
    }

    function getRequiredXpForNextLevel(uint8 currentLevel) public pure returns (uint16) {
        uint16 xp = 16;
        for(uint16 i = 0; i < currentLevel; i++) {
            if (xp <= 112)
            {
                xp += xp / 10;
            }
            else
            {
                xp += (i-14) + 1;
            }
        }
        return xp;
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
        return (1000 + level * 10) * (level / 10 + 1);
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
            uint16 newXp = char.xp + xp;
            uint16 requiredToLevel = getRequiredXpForNextLevel(char.level); // technically next level
            while(newXp > requiredToLevel) {
                newXp = newXp - requiredToLevel;
                char.level = char.level + 1;
                emit LevelUp(id, char.level);
                requiredToLevel = getRequiredXpForNextLevel(char.level);
            }
            char.xp = newXp;
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
            uint64 drainTime = uint64((amount * secondsPerStamina));
            if(isStaminaFull(id)) { // if stamina full, we reset timestamp and drain from that
                setStaminaTimestamp(id, uint64(now-getStaminaMaxWait() + drainTime));
            }
            else {
                setStaminaTimestamp(id, getStaminaTimestamp(id) + drainTime);
            }
            return true;
        }
        else {
            return false;
        }
    }

    function getStaminaPoints(uint256 id) public view returns (uint8) {
        uint64 timestamp = getStaminaTimestamp(id);
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerStamina;
        if(points > maxStamina) {
            points = maxStamina;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view returns (bool) {
        return getStaminaPoints(id) >= maxStamina;
    }

    function getStaminaMaxWait() public pure returns (uint64) {
        return uint64(maxStamina * secondsPerStamina);
    }
}
