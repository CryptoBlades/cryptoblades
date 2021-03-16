pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";

contract Weapons is ERC721, Util {

    address main;

    constructor (address source) public ERC721("Kryptoknight weapon", "KNW") {
        main = source;
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-128
        stars: 1-5 (1,2,3: primary only, 4: one secondary, 5: two secondaries)
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
        stats: STR(fire), DEX(earth), CHA(lightning), INT(water), PWR(traitless)
        base stat rolls: 1*(1-50), 2*(45-75), 3*(70-100), 4*(50-100), 5*(66-100, main is 68-100)
        burns: add level & main stat, and 50% chance to increase secondaries
        power: each point contributes .25% to fight power
        cosmetics: TBD
    */

    struct Weapon {
        uint8 stars; // only the last 3 bits are used. TODO a good filler for the rest? (tiers?)
        uint8 typeseed; // left to right: 2b trait, 6b stat pattern (0-59: 5x4x3)
        uint8 level; // separate from stat1 because stat1 will have a pre-roll
        // cosmetics, todo
        uint8 blade;
        uint8 crossguard;
        uint8 hilt;
        // stats (each point refers to .25% improvement)
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
    }

    Weapon[] public tokens;
    
    event NewWeapon(uint256 weapon);

    modifier restricted() {
        require(main == msg.sender, "Can only be called by main file");
        _;
    }

    function get(uint256 id) public view returns (uint8, uint8, uint8, uint8, uint8, uint8, uint16, uint16, uint16) {
        Weapon memory w = tokens[id];
        return (w.stars, w.typeseed, w.level, w.blade, w.crossguard, w.hilt, w.stat1, w.stat2, w.stat3);
    }

    function mint(address minter, uint8 maxStar) public restricted returns (uint256) {
        uint256 tokenID = tokens.length;

        uint8 stars = 0;
        if(maxStar > 0) {
            stars = uint8(randomSafeMinMax(0,maxStar));
        }

        uint8 typeseed = uint8(randomSafeMinMax(0,255));

        // each point refers to .25%
        // so 1 * 4 is 1%
        uint16 minRoll = 1 * 4;
        uint16 maxRoll = 50 * 4;
        uint8 statCount = 1;
        if(stars == 1) { // 2 star
            minRoll = 45 * 4;
            maxRoll = 75 * 4;
        }
        else if(stars == 2) { // 3 star
            minRoll = 70 * 4;
            maxRoll = 100 * 4;
        }
        else if(stars == 3) { // 4 star
            minRoll = 50 * 4;
            maxRoll = 100 * 4;
            statCount = 2;
        }
        else if(stars > 3) { // 5 star and above
            minRoll = 67 * 4;
            maxRoll = 100 * 4;
            statCount = 3;
        }

        uint16 stat1 = uint16(randomSafeMinMax(minRoll, maxRoll));
        uint16 stat2 = 0;
        uint16 stat3 = 0;
        if(statCount > 1) {
            stat2 = uint16(randomSafeMinMax(minRoll, maxRoll));
        }
        if(statCount > 2) {
            stat3 = uint16(randomSafeMinMax(minRoll, maxRoll));
        }

        uint8 blade = uint8(randomSafeMinMax(0, 255));
        uint8 crossguard = uint8(randomSafeMinMax(0, 255));
        uint8 hilt = uint8(randomSafeMinMax(0, 255));

        tokens.push(Weapon(stars, typeseed, 0 /*level*/, blade, crossguard, hilt, stat1, stat2, stat3));

        _mint(minter, tokenID);
        emit NewWeapon(tokenID);
        return tokenID;
    }

    function getStars(uint256 id) public view returns (uint8) {
        return tokens[id].stars;
    }

    function getTypeseed(uint256 id) public view returns (uint8) {
        return tokens[id].typeseed;
    }

    function getTraitFromTypeseed(uint8 typeseed) public pure returns (uint8) {
        return typeseed & 0x3;
    }

    function getStatPatternFromTypeseed(uint8 typeseed) public pure returns (uint8) {
        return (typeseed >> 2) & 0x3F;
    }

    function getTrait(uint256 id) public view returns (uint8) {
        return getTraitFromTypeseed(getTypeseed(id));
    }

    function getLevel(uint256 id) public view returns (uint8) {
        return tokens[id].level;
    }

    function getStat1(uint256 id) public view returns (uint16) {
        return tokens[id].stat1;
    }

    function getStat2(uint256 id) public view returns (uint16) {
        return tokens[id].stat2;
    }

    function getStat3(uint256 id) public view returns (uint16) {
        return tokens[id].stat3;
    }

    function getPowerMultiplier10k(uint256 id) public view returns (uint32) {
        // returned number is a multiplier that needs dividing by 10000 on use
        // 10000 = 100% = x1.0 and 1 = 0.01% = x0.0001
        // this function does not account for traits
        Weapon memory wep = tokens[id];
        uint16 power = wep.stat1 * 25 + wep.stat2 * 25 + wep.stat3 * 25;
        return 10000/*100% baseline*/ + (power);
    }

    function levelUp(uint256 id) public restricted {
        Weapon storage wep = tokens[id];

        wep.level = wep.level + 1;
        wep.stat1 = wep.stat1 + 1;

        if(wep.stars >= 4 && randomSafeMinMax(0,1) == 0) {
            wep.stat2 = wep.stat2 + 1;
        }
        if(wep.stars >= 5 && randomSafeMinMax(0,1) == 0) {
            wep.stat3 = wep.stat3 + 1;
        }
    }

}

