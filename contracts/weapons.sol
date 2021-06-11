pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "./util.sol";

contract Weapons is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint16;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize () public initializer {
        __ERC721_init("CryptoBlades weapon", "CBW");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_e55d8c5() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        burnPointMultiplier = 2;
        lowStarBurnPowerPerPoint = 15;
        fourStarBurnPowerPerPoint = 30;
        fiveStarBurnPowerPerPoint = 60;
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
        cosmetics: 0-255 but only 24 is used, may want to cap so future expansions dont change existing weps
    */

    struct Weapon {
        uint16 properties; // right to left: 3b stars, 2b trait, 7b stat pattern, 4b EMPTY
        // stats (each point refers to .25% improvement)
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
        uint8 level; // separate from stat1 because stat1 will have a pre-roll
    }

    struct WeaponBurnPoints {
        uint8 lowStarBurnPoints;
        uint8 fourStarBurnPoints;
        uint8 fiveStarBurnPoints;
    }

    struct WeaponCosmetics {
        uint8 version;
        uint256 seed;
    }

    Weapon[] private tokens;
    WeaponCosmetics[] private cosmetics;
    mapping(uint256 => WeaponBurnPoints) burnPoints;

    uint public burnPointMultiplier; // 2
    uint public lowStarBurnPowerPerPoint; // 15
    uint public fourStarBurnPowerPerPoint; // 30
    uint public fiveStarBurnPowerPerPoint; // 60

    event NewWeapon(uint256 indexed weapon, address indexed minter);
    event Reforged(address indexed owner, uint256 indexed reforged, uint256 indexed burned, uint8 lowPoints, uint8 fourPoints, uint8 fivePoints);

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function getStats(uint256 id) internal view
        returns (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level) {

        Weapon memory w = tokens[id];
        return (w.properties, w.stat1, w.stat2, w.stat3, w.level);
    }

    function getCosmetics(uint256 id) internal view
        returns (uint8 _blade, uint8 _crossguard, uint8 _grip, uint8 _pommel) {

        WeaponCosmetics memory wc = cosmetics[id];
        _blade = getRandomCosmetic(wc.seed, 1, 24);
        _crossguard = getRandomCosmetic(wc.seed, 2, 24);
        _grip = getRandomCosmetic(wc.seed, 3, 24);
        _pommel = getRandomCosmetic(wc.seed, 4, 24);
    }

    function get(uint256 id) public view
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level,
            uint8 _blade, uint8 _crossguard, uint8 _grip, uint8 _pommel,
            uint24 _burnPoints, // burn points.. got stack limits so i put them together
            uint24 _bonusPower // bonus power
    ) {
        (_properties, _stat1, _stat2, _stat3, _level) = getStats(id);
        (_blade, _crossguard, _grip, _pommel) = getCosmetics(id);

        WeaponBurnPoints memory wbp = burnPoints[id];
        _burnPoints =
            uint24(wbp.lowStarBurnPoints) |
            (uint24(wbp.fourStarBurnPoints) << 8) |
            (uint24(wbp.fiveStarBurnPoints) << 16);

        _bonusPower = getBonusPower(id);
    }

    function mint(address minter, uint256 seed) public restricted returns(uint256) {

        uint256 stars = getRandomStar(seed);
        return mintWeaponWithStars(minter, stars, seed);
    }

    function mintWeaponWithStars(address minter, uint256 stars, uint256 seed) public restricted returns(uint256) {
        require(stars < 8, "Stars parameter too high! (max 7)");
        (uint16 stat1, uint16 stat2, uint16 stat3) = getStatRolls(stars, seed);

        return performMintWeapon(minter,
            getRandomProperties(stars, seed),
            stat1,
            stat2,
            stat3,
            RandomUtil.combineSeeds(seed,3)
        );
    }

    function performMintWeapon(address minter,
        uint16 properties,
        uint16 stat1, uint16 stat2, uint16 stat3,
        uint256 cosmeticSeed
    ) public restricted returns(uint256) {

        uint256 tokenID = tokens.length;
        tokens.push(Weapon(properties, stat1, stat2, stat3, 0));
        cosmetics.push(WeaponCosmetics(0, cosmeticSeed));
        _mint(minter, tokenID);
        emit NewWeapon(tokenID, minter);
        return tokenID;
    }

    function getRandomProperties(uint256 stars, uint256 seed) public pure returns (uint16) {
        return uint16((stars & 0x7) // stars aren't randomized here!
            | ((RandomUtil.randomSeededMinMax(0,3,RandomUtil.combineSeeds(seed,1)) & 0x3) << 3) // trait
            | ((RandomUtil.randomSeededMinMax(0,124,RandomUtil.combineSeeds(seed,2)) & 0x7F) << 5)); // statPattern
    }

    function getRandomStar(uint256 seed) private pure returns (uint8) {
        uint256 roll = seed % 100;
        // will need revision, possibly manual configuration if we support more than 5 stars
        if(roll < 1) {
            return 4; // 5* at 1%
        }
        else if(roll < 6) { // 4* at 5%
            return 3;
        }
        else if(roll < 21) { // 3* at 15%
            return 2;
        }
        else if(roll < 56) { // 2* at 35%
            return 1;
        }
        else {
            return 0; // 1* at 44%
        }
    }

    function getStatRolls(uint256 stars, uint256 seed) private pure returns (uint16, uint16, uint16) {
        // each point refers to .25%
        // so 1 * 4 is 1%
        uint16 minRoll = getStatMinRoll(stars);
        uint16 maxRoll = getStatMaxRoll(stars);
        uint8 statCount = getStatCount(stars);

        uint16 stat1 = getRandomStat(minRoll, maxRoll, seed, 5);
        uint16 stat2 = 0;
        uint16 stat3 = 0;
        if(statCount > 1) {
            stat2 = getRandomStat(minRoll, maxRoll, seed, 3);
        }
        if(statCount > 2) {
            stat3 = getRandomStat(minRoll, maxRoll, seed, 4);
        }
        return (stat1, stat2, stat3);
    }

    function getRandomStat(uint16 minRoll, uint16 maxRoll, uint256 seed, uint256 seed2) public pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(minRoll, maxRoll,RandomUtil.combineSeeds(seed, seed2)));
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint8 limit) public pure returns (uint8) {
        return uint8(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function getStatMinRoll(uint256 stars) public pure returns (uint16) {
        // 1 star
        if (stars == 0) return 4;
        // 2 star
        if (stars == 1) return 180;
        // 3 star
        if (stars == 2) return 280;
        // 4 star
        if (stars == 3) return 200;
        // 5+ star
        return 268;
    }

    function getStatMaxRoll(uint256 stars) public pure returns (uint16) {
        uint16 maxRoll = uint16(SafeMath.mul(50, 4));
        if(stars == 1) { // 2 star
            maxRoll = uint16(SafeMath.mul(75, 4));
        }
        else if(stars == 2) { // 3 star
            maxRoll = uint16(SafeMath.mul(100, 4));
        }
        else if(stars == 3) { // 4 star
            maxRoll = uint16(SafeMath.mul(100, 4));
        }
        else if(stars > 3) { // 5 star and above
            maxRoll = uint16(SafeMath.mul(100, 4));
        }
        return maxRoll;
    }

    function getStatCount(uint256 stars) public pure returns (uint8) {
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
        return uint8(uint256(statPattern) % 5); // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getStat2Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 5) % 5); // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getStat3Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 25) % 5); // 0-3 regular traits, 4 = traitless (PWR)
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
        int128 powerPerPoint = ABDKMath64x64.divu(1, 400); // 0.25% or x0.0025
        int128 stat1 = wep.stat1.fromUInt().mul(powerPerPoint);
        int128 stat2 = wep.stat2.fromUInt().mul(powerPerPoint);
        int128 stat3 = wep.stat3.fromUInt().mul(powerPerPoint);
        return ABDKMath64x64.fromUInt(1).add(stat1).add(stat2).add(stat3);
    }

    function getPowerMultiplierForTrait(uint256 id, uint8 trait) public view returns(int128) {
        // Does not include character trait to weapon trait match
        // Only counts arbitrary trait to weapon stat trait
        // This function can be used by frontend to get expected % bonus for each type
        // Making it easy to see on the market how useful it will be to you
        Weapon memory wep = tokens[id];
        int128 powerPerPoint = ABDKMath64x64.divu(1, 400); // 0.25% or x0.0025
        int128 matchingPowerPerPoint = powerPerPoint.mul(ABDKMath64x64.divu(107, 100)); // +7%
        int128 powerPerPWRPoint = powerPerPoint.mul(ABDKMath64x64.divu(103, 100)); // +3%
        uint8 statPattern = getStatPatternFromProperties(wep.properties);
        int128 result = ABDKMath64x64.fromUInt(1);

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

    function reforge(uint256 reforgeID, uint256 burnID) public restricted {
        WeaponBurnPoints storage wbp = burnPoints[reforgeID];
        Weapon storage burning = tokens[burnID];

        if(getStarsFromProperties(burning.properties) == 0) { // 1 star
            require(wbp.lowStarBurnPoints < 100, "Low star burn points are capped");
            wbp.lowStarBurnPoints = uint8(burnPointMultiplier.mul((wbp.lowStarBurnPoints < 10) ? 2 : 1)
                .add(wbp.lowStarBurnPoints));
            if(wbp.lowStarBurnPoints > 100)
                wbp.lowStarBurnPoints = 100;
        }
        else if(getStarsFromProperties(burning.properties) == 1) { // 2 star
            require(wbp.lowStarBurnPoints < 100, "Low star burn points are capped");
            wbp.lowStarBurnPoints = uint8(burnPointMultiplier.mul((wbp.lowStarBurnPoints < 30) ? 2 : 1)
                .add(wbp.lowStarBurnPoints));
            if(wbp.lowStarBurnPoints > 100)
                wbp.lowStarBurnPoints = 100;
        }
        else if(getStarsFromProperties(burning.properties) == 2) { // 3 star
            require(wbp.lowStarBurnPoints < 100, "Low star burn points are capped");
            wbp.lowStarBurnPoints = uint8(burnPointMultiplier.mul((wbp.lowStarBurnPoints < 50) ? 4 : 2)
                .add(wbp.lowStarBurnPoints));
            if(wbp.lowStarBurnPoints > 100)
                wbp.lowStarBurnPoints = 100;
        }
        else if(getStarsFromProperties(burning.properties) == 3) { // 4 star
            require(wbp.fourStarBurnPoints < 25, "Four star burn points are capped");
            wbp.fourStarBurnPoints = uint8(burnPointMultiplier.add(wbp.fourStarBurnPoints));
            if(wbp.fourStarBurnPoints > 25)
                wbp.fourStarBurnPoints = 25;
        }
        else if(getStarsFromProperties(burning.properties) == 4) { // 5 star
            require(wbp.fiveStarBurnPoints < 10, "Five star burn points are capped");
            wbp.fiveStarBurnPoints = uint8(burnPointMultiplier.add(wbp.fiveStarBurnPoints));
            if(wbp.fiveStarBurnPoints > 10)
                wbp.fiveStarBurnPoints = 10;
        }
        _burn(burnID);
        emit Reforged(
            ownerOf(reforgeID),
            reforgeID,
            burnID,
            wbp.lowStarBurnPoints,
            wbp.fourStarBurnPoints,
            wbp.fiveStarBurnPoints
        );
    }

    // UNUSED FOR NOW!
    function levelUp(uint256 id, uint256 seed) private {
        Weapon storage wep = tokens[id];

        wep.level = uint8(SafeMath.add(wep.level, 1));
        wep.stat1 = uint16(SafeMath.add(wep.stat1, 1));

        uint8 stars = getStarsFromProperties(wep.properties);

        if(stars >= 4 && RandomUtil.randomSeededMinMax(0,1, seed) == 0) {
            wep.stat2 = uint16(SafeMath.add(wep.stat2, 1));
        }
        if(stars >= 5 && RandomUtil.randomSeededMinMax(0,1, RandomUtil.combineSeeds(seed,1)) == 0) {
            wep.stat3 = uint16(SafeMath.add(wep.stat3, 1));
        }
    }

    function getBonusPower(uint256 id) public view returns (uint24) {
        Weapon storage wep = tokens[id];
        WeaponBurnPoints storage wbp = burnPoints[id];
        return uint24(lowStarBurnPowerPerPoint.mul(wbp.lowStarBurnPoints)
            .add(fourStarBurnPowerPerPoint.mul(wbp.fourStarBurnPoints))
            .add(fiveStarBurnPowerPerPoint.mul(wbp.fiveStarBurnPoints))
            .add(uint256(15).mul(wep.level)) // TEMP: UNTIL WE IMPLEMENT WEAPON LEVELS
        );
    }

    function setBurnPointMultiplier(uint256 multiplier) public restricted {
        burnPointMultiplier = multiplier;
    }
    function setLowStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        lowStarBurnPowerPerPoint = powerPerBurnPoint;
    }
    function setFourStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        fourStarBurnPowerPerPoint = powerPerBurnPoint;
    }
    function setFiveStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        fiveStarBurnPowerPerPoint = powerPerBurnPoint;
    }

}

