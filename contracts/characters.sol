pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";

contract Characters is ERC721, Util {

    address main;

    constructor (address source) public ERC721("Kryptoknight", "KNT") {
        main = source;
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
        uint64 appearance; // placeholder; cat ears, cup size and shit. PIMP MY KNIGHT
    }

    Character[] public tokens;

    uint256 public maxStamina = 200;
    uint256 public secondsPerStamina = 300; //5 * 60
    
    event NewCharacter(uint256 character);
    event LevelUp(uint256 character, uint16 level);

    modifier restricted() {
        require(main == msg.sender, "Can only be called by main file");
        _;
    }

    function get(uint256 id) public view returns (uint16, uint8, uint8, uint64, uint64) {
        Character memory c = tokens[id];
        return (c.xp, c.level, c.trait, c.staminaTimestamp, c.appearance);
    }

    function mint(address minter) public restricted returns (uint256) {
        uint256 tokenID = tokens.length;

        uint16 xp = 0;
        uint8 level = 0; // 1
        uint8 trait = uint8(randomSafeMinMax(0,3));
        uint64 staminaTimestamp = uint64(now);
        uint64 appearance = 0;

        tokens.push(Character(xp, level, trait, staminaTimestamp, appearance));
        _mint(minter, tokenID);
        emit NewCharacter(tokenID);
        return tokenID;
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
        uint8 level = getLevel(id);
        return (1000 + level * 10) * (level / 10 + 1); // 1010 to 3560 * 1 to 26 = 1010 to 92560
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
        }
    }

    function getAppearance(uint256 id) public view returns (uint64) {
        return tokens[id].appearance;
    }

    function getStaminaTimestamp(uint256 id) public view returns (uint64) {
        return tokens[id].staminaTimestamp;
    }

    function setStaminaTimestamp(uint256 id, uint64 timestamp) public restricted {
        tokens[id].staminaTimestamp = timestamp;
    }

    function getStaminaPoints(uint256 id) public view returns (uint8) {
        return uint8(getStaminaTimestamp(id) / secondsPerStamina);
    }
    
    function getStaminaMaxWait() public view returns (uint64) {
        return uint64(maxStamina * secondsPerStamina);
    }
}
