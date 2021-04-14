pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "./util.sol";

contract Weapons is ERC721, Util {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for uint16;

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
        uint16 properties; // right to left: 3b stars, 2b trait, 7b stat pattern, 4b EMPTY
        /*uint8 stars; // only the last 3 bits are used. TODO a good filler for the rest? (tiers?)
        uint8 trait; // only 2bits used on right
        uint8 statPattern; // 7bits (0-124) on right used for */
        // stats (each point refers to .25% improvement)
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
        uint8 level; // separate from stat1 because stat1 will have a pre-roll
        // cosmetics, todo
        uint8 blade;
        uint8 crossguard;
        uint8 grip;
        uint8 pommel;
    }

    Weapon[] public tokens;
    
    event NewWeapon(uint256 weapon);

    modifier restricted() {
        require(main == msg.sender, "Can only be called by main file");
        _;
    }

    function get(uint256 id) public view returns (uint16, uint16, uint16, uint16, uint8, uint8, uint8, uint8, uint8) {
        Weapon memory w = tokens[id];
        return (w.properties, w.stat1, w.stat2, w.stat3, w.level, w.blade, w.crossguard, w.grip, w.pommel);
    }

    function mint(address minter, uint8 maxStar) public restricted returns (uint256) {
        uint256 tokenID = tokens.length;

        uint256 stars = 0;
        if(maxStar > 0) {
            stars = randomSafeMinMax(0,maxStar);
        }

        uint16 properties = uint16((stars & 0x7)
            | ((randomSafeMinMax(0,3) << 3) & 0x3) // trait
            | ((randomSafeMinMax(0,124) << 5) & 0x7F)); // statPattern

        // each point refers to .25%
        // so 1 * 4 is 1%
        uint16 minRoll = getStatMinRoll(stars);
        uint16 maxRoll = getStatMaxRoll(stars);
        uint8 statCount = getStatCount(stars);

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
        uint8 grip = uint8(randomSafeMinMax(0, 255));
        uint8 pommel = uint8(randomSafeMinMax(0, 255));

        tokens.push(Weapon(properties, uint16(randomSafeMinMax(minRoll, maxRoll)), stat2, stat3, 0/*level*/, blade, crossguard, grip, pommel));

        _mint(minter, tokenID);
        emit NewWeapon(tokenID);
        return tokenID;
    }

    function getStatMinRoll(uint256 stars) private pure returns (uint16) {
        uint16 minRoll = 1 * 4;
        if(stars == 1) { // 2 star
            minRoll = 45 * 4;
        }
        else if(stars == 2) { // 3 star
            minRoll = 70 * 4;
        }
        else if(stars == 3) { // 4 star
            minRoll = 50 * 4;
        }
        else if(stars > 3) { // 5 star and above
            minRoll = 67 * 4;
        }
        return minRoll;
    }

    function getStatMaxRoll(uint256 stars) private pure returns (uint16) {
        uint16 maxRoll = 50 * 4;
        if(stars == 1) { // 2 star
            maxRoll = 75 * 4;
        }
        else if(stars == 2) { // 3 star
            maxRoll = 100 * 4;
        }
        else if(stars == 3) { // 4 star
            maxRoll = 100 * 4;
        }
        else if(stars > 3) { // 5 star and above
            maxRoll = 100 * 4;
        }
        return maxRoll;
    }

    function getStatCount(uint256 stars) private pure returns (uint8) {
        uint8 statCount = 1;
        if(stars == 3) { // 4 star
            statCount = 2;
        }
        else if(stars > 3) { // 5 star and above
            statCount = 3;
        }
        return statCount;
    }

    function getProperties(uint256 id) public view returns (uint16) {
        return tokens[id].properties;
    }

    function getStars(uint256 id) public view returns (uint8) {
        return getStarsFromProperties(getProperties(id));
    }

    function getStarsFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8(properties & 0x7); // first two bits for stars
    }

    function getTrait(uint256 id) public view returns (uint8) {
        return getTraitFromProperties(getProperties(id));
    }

    function getTraitFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 3) & 0x3); // two bits after star bits (3)
    }

    function getStatPattern(uint256 id) public view returns (uint8) {
        return getStatPatternFromProperties(getProperties(id));
    }

    function getStatPatternFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 5) & 0x7F); // 7 bits after star(3) and trait(2) bits
    }

    function getStat1Trait(uint8 statPattern) public pure returns (uint8) {
        return statPattern % 5; // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getStat2Trait(uint8 statPattern) public pure returns (uint8) {
        return (statPattern / 5) % 5; // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getStat3Trait(uint8 statPattern) public pure returns (uint8) {
        return (statPattern / 5 / 5) % 5; // 0-3 regular traits, 4 = traitless (PWR)
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

    function getPowerMultiplier(uint256 id) public view returns (int128) {
        // returns a 64.64 fixed point number for power multiplier
        // this function does not account for traits
        // it is used to calculate base enemy powers for targeting
        Weapon memory wep = tokens[id];
        int128 powerPerPoint = uint256(1).divu(400); // 0.25% or x0.0025
        int128 stat1 = wep.stat1.fromUInt().mul(powerPerPoint);
        int128 stat2 = wep.stat2.fromUInt().mul(powerPerPoint);
        int128 stat3 = wep.stat3.fromUInt().mul(powerPerPoint);
        return uint256(1).fromUInt().add(stat1).add(stat2).add(stat3);
    }

    function getPowerMultiplierForTrait(uint256 id, uint8 trait) public view returns(int128) {
        // Does not include character trait to weapon trait match
        // Only counts arbitrary trait to weapon stat trait
        // This function can be used by frontend to get expected % bonus for each type
        // Making it easy to see on the market how useful it will be to you
        Weapon memory wep = tokens[id];
        int128 powerPerPoint = uint256(1).divu(400); // 0.25% or x0.0025
        int128 matchingPowerPerPoint = powerPerPoint.mul(uint256(107).divu(100)); // +7%
        int128 powerPerPWRPoint = powerPerPoint.mul(uint256(103).divu(100)); // +3%
        uint8 statPattern = getStatPatternFromProperties(wep.properties);
        int128 result = uint256(1).fromUInt();

        if(getStat1Trait(statPattern) == trait)
            result = result.add(wep.stat1.fromUInt().mul(matchingPowerPerPoint));
        else if(getStat1Trait(statPattern) == 4) // PWR, traitless
            result = result.add(wep.stat1.fromUInt().mul(powerPerPWRPoint));
        else
            result = result.add(wep.stat1.fromUInt().mul(powerPerPoint));
        
        if(getStat2Trait(statPattern) == trait)
            result = result.add(wep.stat2.fromUInt().mul(matchingPowerPerPoint));
        else if(getStat2Trait(statPattern) == 4) // PWR, traitless
            result = result.add(wep.stat2.fromUInt().mul(powerPerPWRPoint));
        else
            result = result.add(wep.stat2.fromUInt().mul(powerPerPoint));

        if(getStat3Trait(statPattern) == trait)
            result = result.add(wep.stat3.fromUInt().mul(matchingPowerPerPoint));
        else if(getStat3Trait(statPattern) == 4) // PWR, traitless
            result = result.add(wep.stat3.fromUInt().mul(powerPerPWRPoint));
        else
            result = result.add(wep.stat3.fromUInt().mul(powerPerPoint));

        return result;
    }

    function levelUp(uint256 id) public restricted {
        Weapon storage wep = tokens[id];

        wep.level = wep.level + 1;
        wep.stat1 = wep.stat1 + 1;

        uint8 stars = getStarsFromProperties(wep.properties);

        if(stars >= 4 && randomSafeMinMax(0,1) == 0) {
            wep.stat2 = wep.stat2 + 1;
        }
        if(stars >= 5 && randomSafeMinMax(0,1) == 0) {
            wep.stat3 = wep.stat3 + 1;
        }
    }

}

