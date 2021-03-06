pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";

contract Weapons is ERC721Full, Util {

    constructor () public ERC721Full("Kryptoknight weapon", "KNW") {
    }

    struct Weapon {
        uint24 properties; // right to left: 3b stars, 7b blade, 7b crossguard, 7b hilt (combined parts for uniques)
        uint24 stats; // right to left: 3b trait, 7b stat1/level, 7b stat2, 7b stat3
        uint16 xp; // gained since last level, not total
    }

    uint256 mintWeaponFee = 200;
    uint256 reforgeWeaponFee = 100;

    Weapon[] public tokens;

    modifier isWeaponOwner(uint256 weaponID) {
        require(ownerOf(weaponID) == msg.sender);
        _;
    }

    function mint() public returns (uint256) {
        uint64 appearance = 0;
        uint256 tokenID = tokens.push(Weapon(0,0,0));
        _mint(msg.sender, tokenID);
        return tokenID;
    }

    function getStars(uint24 properties) public pure returns (uint8) {
        return (uint8)(properties & 0x7);
    }

    function getBlade(uint24 properties) external pure returns (uint8) {
        return (uint8)((properties >> 3) & 0x7F);
    }

    function getCrossguard(uint24 properties) external pure returns (uint8) {
        return (uint8)((properties >> 10) & 0x7F);
    }

    function getHilt(uint24 properties) external pure returns (uint8) {
        return (uint8)((properties >> 17) & 0x7F);
    }

    function getUnique(uint24 properties) external pure returns (uint24) {
        return (uint24)((properties >> 3) & 0x1FFFFF);
    }

    function getXp(uint256 weaponID) external view returns (uint16) {
        return tokens[weaponID].xp;
    }

    function getTrait(uint24 stats) public pure returns (uint8) {
        return (uint8)(stats & 0x7);
    }

    function getLevel(uint24 stats) public pure returns (uint8) {
        return (uint8)((stats >> 3) & 0x7);
    }

    function getStat2(uint24 stats) public pure returns (uint8) {
        return (uint8)((stats >> 10) & 0x7);
    }

    function getStat3(uint24 stats) public pure returns (uint8) {
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

    function levelUp(uint256 weaponID) internal {
        increaseLevel(reforgeID);
        if(forgeWeaponStar >= 4 && random(0,1) == 0) {
            increaseStat2(reforgeID);
        }
        if(forgeWeaponStar >= 5 && random(0,1) == 0) {
            increaseStat3(reforgeID);
        }
    }

    function increaseLevel(uint256 weaponID) internal {
        Weapon storage w = tokens[weaponID];
        uint8 level = getLevel(w.stats);
        level += 1;
        w.stats = w.stats & 0xFFFC07; // nulls out the level bits
        w.stats = w.stats | (level << 3);
    }
    
    function increaseStat2(uint256 weaponID) internal {
        Weapon storage w = tokens[weaponID];
        uint8 stat2 = getStat2(w.stats);
        stat2 += 1;
        w.stats = w.stats & 0xFE03FF; // nulls out the stat2 bits
        w.stats = w.stats | (stat2 << 10);
    }
    
    function increaseStat3(uint256 weaponID) internal {
        Weapon storage w = tokens[weaponID];
        uint8 stat3 = getStat3(w.stats);
        stat3 += 1;
        w.stats = w.stats & 0x1FFFF; // nulls out the stat3 bits
        w.stats = w.stats | (stat3 << 17);
    }
}

