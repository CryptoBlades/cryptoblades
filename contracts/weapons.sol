pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./data.sol";

contract Weapons is ERC721, Data {

    address main;

    constructor (address source) public ERC721("Kryptoknight weapon", "KNW") {
        main = source;
    }

    struct Weapon {
        uint24 properties; // right to left: 3b stars, 7b blade, 7b crossguard, 7b hilt (combined parts for uniques)
        uint24 stats; // right to left: 3b trait, 7b stat1/level, 7b stat2, 7b stat3
        uint16 xp; // gained since last level, not total
    }

    Weapon[] public tokens;

    modifier restricted() {
        require(main == msg.sender);
        _;
    }
    modifier isWeaponOwner(uint256 weaponID) {
        require(ownerOf(weaponID) == msg.sender);
        _;
    }
    
    function mint() public restricted returns (uint256) {
        uint64 appearance = 0;
        uint256 tokenID = tokens.length;
        tokens.push(Weapon(0,0,0));
        _mint(msg.sender, tokenID);
        return tokenID;
    }

    function getStars(uint256 id) public view returns (uint8) {
        return getStarsFromProperties(tokens[id].properties);
    }

    function getStarsFromProperties(uint24 properties) public pure returns (uint8) {
        return (uint8)(properties & 0x7);
    }

    function getBladeFromProperties(uint24 properties) external pure returns (uint8) {
        return (uint8)((properties >> 3) & 0x7F);
    }

    function getCrossguardFromProperties(uint24 properties) external pure returns (uint8) {
        return (uint8)((properties >> 10) & 0x7F);
    }

    function getHiltFromProperties(uint24 properties) external pure returns (uint8) {
        return (uint8)((properties >> 17) & 0x7F);
    }

    function getUniqueFromProperties(uint24 properties) external pure returns (uint24) {
        return (uint24)((properties >> 3) & 0x1FFFFF);
    }

    function getXp(uint256 id) public view returns (uint16) {
        return tokens[id].xp;
    }

    function setXp(uint256 id, uint16 xp) public restricted {
        tokens[id].xp = xp;
    }

    function getTrait(uint256 id) public view returns (uint8) {
        return getTraitFromStats(tokens[id].stats);
    }

    function getTraitFromStats(uint24 stats) public pure returns (uint8) {
        return (uint8)(stats & 0x7);
    }

    function getLevel(uint256 id) public view returns (uint8) {
        return getLevelFromStats(tokens[id].stats);
    }

    function getLevelFromStats(uint24 stats) public pure returns (uint8) {
        return (uint8)((stats >> 3) & 0x7);
    }

    function getStat2(uint256 id) public view returns (uint8) {
        return getStat2FromStats(tokens[id].stats);
    }

    function getStat2FromStats(uint24 stats) public pure returns (uint8) {
        return (uint8)((stats >> 10) & 0x7);
    }

    function getStat3(uint256 id) public view returns (uint8) {
        return getStat3FromStats(tokens[id].stats);
    }

    function getStat3FromStats(uint24 stats) public pure returns (uint8) {
        return (uint8)((stats >> 17) & 0x7);
    }

    function getRequiredXpForLevel(uint8 level) public pure returns (uint16) {
        uint16 xp = 16;
        for(uint16 i = 1; i < level; i++) {
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

    function gainXp(uint256 id, uint32 xp) public restricted returns (uint8) {
        
        uint8 level = getLevel(id);
        uint32 newXp = uint32(getXp(id)) + xp;
        uint16 xpToLevel = getRequiredXpForLevel(level);

        while (xpToLevel <= newXp) {
            newXp - xpToLevel;
            levelUp(id);
            level++;
            getRequiredXpForLevel(level);
        }
        setXp(id, uint16(newXp));
    }

    function levelUp(uint256 id) public restricted {
        Weapons.Weapon storage wep = tokens[id];
        uint8 stars = getStars(wep.properties);

        increaseLevel(id);
        if(stars >= 4 && random(0,1) == 0) {
            increaseStat2(id);
        }
        if(stars >= 5 && random(0,1) == 0) {
            increaseStat3(id);
        }
    }

    function increaseLevel(uint256 id) public restricted {
        Weapon storage w = tokens[id];
        uint8 level = getLevel(w.stats);
        level += 1;
        w.stats = w.stats & 0xFFFC07; // nulls out the level bits
        w.stats = w.stats | (level << 3);
    }
    
    function increaseStat2(uint256 id) public restricted {
        Weapon storage w = tokens[id];
        uint8 stat2 = getStat2(w.stats);
        stat2 += 1;
        w.stats = w.stats & 0xFE03FF; // nulls out the stat2 bits
        w.stats = w.stats | (stat2 << 10);
    }
    
    function increaseStat3(uint256 id) public restricted {
        Weapon storage w = tokens[id];
        uint8 stat3 = getStat3(w.stats);
        stat3 += 1;
        w.stats = w.stats & 0x1FFFF; // nulls out the stat3 bits
        w.stats = w.stats | (stat3 << 17);
    }
}

