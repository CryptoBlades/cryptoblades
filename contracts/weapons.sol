pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./util.sol";

contract Weapons is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint16;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP = keccak256("RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP");

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

    function migrateTo_aa9da90() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        oneFrac = ABDKMath64x64.fromUInt(1);
        powerMultPerPointBasic =  ABDKMath64x64.divu(1, 400);// 0.25%
        powerMultPerPointPWR = powerMultPerPointBasic.mul(ABDKMath64x64.divu(103, 100)); // 0.2575% (+3%)
        powerMultPerPointMatching = powerMultPerPointBasic.mul(ABDKMath64x64.divu(107, 100)); // 0.2675% (+7%)
    }

    function migrateTo_951a020() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        // Apparently ERC165 interfaces cannot be removed in this version of the OpenZeppelin library.
        // But if we remove the registration, then while local deployments would not register the interface ID,
        // existing deployments on both testnet and mainnet would still be registered to handle it.
        // That sort of inconsistency is a good way to attract bugs that only happens on some environments.
        // Hence, we keep registering the interface despite not actually implementing the interface.
        _registerInterface(0xe62e6974); // TransferCooldownableInterfaceId.interfaceId()
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

    int128 public oneFrac; // 1.0
    int128 public powerMultPerPointBasic; // 0.25%
    int128 public powerMultPerPointPWR; // 0.2575% (+3%)
    int128 public powerMultPerPointMatching; // 0.2675% (+7%)

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(uint256 => uint256) public lastTransferTimestamp;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    mapping(uint256 => uint64) durabilityTimestamp;

    uint256 public constant maxDurability = 20;
    uint256 public constant secondsPerDurability = 3000; //50 * 60

    mapping(address => uint256) burnDust; // user address : burned item dust counts

    event Burned(address indexed owner, uint256 indexed burned);
    event NewWeapon(uint256 indexed weapon, address indexed minter);
    event Reforged(address indexed owner, uint256 indexed reforged, uint256 indexed burned, uint8 lowPoints, uint8 fourPoints, uint8 fivePoints);
    event ReforgedWithDust(address indexed owner, uint256 indexed reforged, uint8 lowDust, uint8 fourDust, uint8 fiveDust, uint8 lowPoints, uint8 fourPoints, uint8 fivePoints);

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

    function get(uint256 id) public view noFreshLookup(id)
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level,
            uint8 _blade, uint8 _crossguard, uint8 _grip, uint8 _pommel,
            uint24 _burnPoints, // burn points.. got stack limits so i put them together
            uint24 _bonusPower // bonus power
    ) {
        return _get(id);
    }

    function _get(uint256 id) internal view
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
        uint256 stars;
        uint256 roll = seed % 100;
        // will need revision, possibly manual configuration if we support more than 5 stars
        if(roll < 1) {
            stars = 4; // 5* at 1%
        }
        else if(roll < 6) { // 4* at 5%
            stars = 3;
        }
        else if(roll < 21) { // 3* at 15%
            stars = 2;
        }
        else if(roll < 56) { // 2* at 35%
            stars = 1;
        }
        else {
            stars = 0; // 1* at 44%
        }

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

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        tokens.push(Weapon(properties, stat1, stat2, stat3, 0));
        cosmetics.push(WeaponCosmetics(0, cosmeticSeed));
        _mint(minter, tokenID);
        durabilityTimestamp[tokenID] = uint64(now.sub(getDurabilityMaxWait()));

        emit NewWeapon(tokenID, minter);
        return tokenID;
    }

    function getRandomProperties(uint256 stars, uint256 seed) public pure returns (uint16) {
        return uint16((stars & 0x7) // stars aren't randomized here!
            | ((RandomUtil.randomSeededMinMax(0,3,RandomUtil.combineSeeds(seed,1)) & 0x3) << 3) // trait
            | ((RandomUtil.randomSeededMinMax(0,124,RandomUtil.combineSeeds(seed,2)) & 0x7F) << 5)); // statPattern
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
        // 3+ star
        if (stars > 1) return 400;
        // 2 star
        if (stars > 0) return 300;
        // 1 star
        return 200;
    }

    function getStatCount(uint256 stars) public pure returns (uint8) {
        // 1-2 star
        if (stars < 3) return 1;
        // 3+ star
        return uint8(stars)-1;
    }

    function getProperties(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].properties;
    }

    function getStars(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStarsFromProperties(getProperties(id));
    }

    function getStarsFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8(properties & 0x7); // first two bits for stars
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getTraitFromProperties(getProperties(id));
    }

    function getTraitFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 3) & 0x3); // two bits after star bits (3)
    }

    function getStatPattern(uint256 id) public view noFreshLookup(id) returns (uint8) {
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

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].level;
    }

    function getStat1(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat1;
    }

    function getStat2(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat2;
    }

    function getStat3(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat3;
    }

    function getPowerMultiplier(uint256 id) public view noFreshLookup(id) returns (int128) {
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

    function getPowerMultiplierForTrait(
        uint16 properties,
        uint16 stat1,
        uint16 stat2,
        uint16 stat3,
        uint8 trait
    ) public view returns(int128) {
        // Does not include character trait to weapon trait match
        // Only counts arbitrary trait to weapon stat trait
        // This function can be used by frontend to get expected % bonus for each type
        // Making it easy to see on the market how useful it will be to you
        uint8 statPattern = getStatPatternFromProperties(properties);
        int128 result = oneFrac;

        if(getStat1Trait(statPattern) == trait)
            result = result.add(stat1.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat1Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat1.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat1.fromUInt().mul(powerMultPerPointBasic));

        if(getStat2Trait(statPattern) == trait)
            result = result.add(stat2.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat2Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat2.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat2.fromUInt().mul(powerMultPerPointBasic));

        if(getStat3Trait(statPattern) == trait)
            result = result.add(stat3.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat3Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat3.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat3.fromUInt().mul(powerMultPerPointBasic));

        return result;
    }

    function getDustSupplies(address playerAddress) public view returns (uint32[] memory) {
        uint256 burnDustValue = burnDust[playerAddress];
        uint32[] memory supplies = new uint32[](3);
        supplies[0] = uint32(burnDustValue);
        supplies[1] = uint32(burnDustValue >> 32);
        supplies[2] = uint32(burnDustValue >> 64);
        return supplies;
    }

    function _setDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint256 burnDustValue = (uint256(amount5B) << 64) + (uint256(amount4B) << 32) + amountLB;
        burnDust[playerAddress] = burnDustValue;
    }

    function _decrementDustSuppliesCheck(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint32[] memory supplies = getDustSupplies(playerAddress);
        require(supplies[0] >= amountLB, "Dust LB supply needed");
        require(supplies[1] >= amount4B, "Dust 4B supply needed");
        require(supplies[2] >= amount5B, "Dust 5B supply needed");
    }

    function _decrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint32[] memory supplies = getDustSupplies(playerAddress);
        supplies[0] -= amountLB;
        supplies[1] -= amount4B;
        supplies[2] -= amount5B;
        _setDustSupplies(playerAddress, supplies[0], supplies[1], supplies[2]);
    }

    function _incrementDustSuppliesCheck(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint32[] memory supplies = getDustSupplies(playerAddress);
        require(uint256(supplies[0]) + amountLB <= 0xFFFFFFFF, "Dust LB supply capped");
        require(uint256(supplies[1]) + amount4B <= 0xFFFFFFFF, "Dust 4B supply capped");
        require(uint256(supplies[2]) + amount5B <= 0xFFFFFFFF, "Dust 5B supply capped");
    }

    function _incrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        _incrementDustSuppliesCheck(playerAddress, amountLB, amount4B, amount5B);
        uint32[] memory supplies = getDustSupplies(playerAddress);
        supplies[0] += amountLB;
        supplies[1] += amount4B;
        supplies[2] += amount5B;
        _setDustSupplies(playerAddress, supplies[0], supplies[1], supplies[2]);
    }

    function _calculateBurnValues(uint256 burnID) public view returns(uint8[] memory) {
        uint8[] memory values = new uint8[](3);

        // Carried burn points.
        WeaponBurnPoints storage burningbp = burnPoints[burnID];
        values[0] = (burningbp.lowStarBurnPoints + 1) / 2;
        values[1] = (burningbp.fourStarBurnPoints + 1) / 2;
        values[2] = (burningbp.fiveStarBurnPoints + 1) / 2;

        // Stars-based burn points.
        Weapon storage burning = tokens[burnID];
        uint8 stars = getStarsFromProperties(burning.properties);
        if(stars < 3) { // 1-3 star
            values[0] += uint8(burnPointMultiplier * (stars + 1));
        }
        else if(stars == 3) { // 4 star
            values[1] += uint8(burnPointMultiplier);
        }
        else if(stars == 4) { // 5 star
            values[2] += uint8(burnPointMultiplier);
        }

        return values;
    }

    function burn(uint256 burnID) public restricted {
        uint8[] memory values = _calculateBurnValues(burnID);

        address burnOwner = ownerOf(burnID);

        // While this may seem redundant, _burn could fail so
        // dust cannot be pre-incremented.
        _incrementDustSuppliesCheck(burnOwner, values[0], values[1], values[2]);

        _burn(burnID);
        _incrementDustSupplies(burnOwner, values[0], values[1], values[2]);

        emit Burned(
            burnOwner,
            burnID
        );
    }

    function reforge(uint256 reforgeID, uint256 burnID) public restricted {
        uint8[] memory values = _calculateBurnValues(burnID);

        // Note: preexisting issue of applying burn points even if _burn fails.
        _applyBurnPoints(reforgeID, values[0], values[1], values[2]);
        _burn(burnID);

        WeaponBurnPoints storage wbp = burnPoints[reforgeID];
        emit Reforged(
            ownerOf(reforgeID),
            reforgeID,
            burnID,
            wbp.lowStarBurnPoints,
            wbp.fourStarBurnPoints,
            wbp.fiveStarBurnPoints
        );
    }

    function reforgeWithDust(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) public restricted {
        // While this may seem redundant, _applyBurnPoints could fail so
        // dust cannot be pre-decremented.
        _decrementDustSuppliesCheck(ownerOf(reforgeID), amountLB, amount4B, amount5B);

        _applyBurnPoints(reforgeID, amountLB, amount4B, amount5B);
        _decrementDustSupplies(ownerOf(reforgeID), amountLB, amount4B, amount5B);

        WeaponBurnPoints storage wbp = burnPoints[reforgeID];
        emit ReforgedWithDust(
            ownerOf(reforgeID),
            reforgeID,
            amountLB,
            amount4B,
            amount5B,
            wbp.lowStarBurnPoints,
            wbp.fourStarBurnPoints,
            wbp.fiveStarBurnPoints
        );
    }

    function _applyBurnPoints(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) private {
        WeaponBurnPoints storage wbp = burnPoints[reforgeID];

        if(amountLB > 0) {
            require(wbp.lowStarBurnPoints < 100, "Low star burn points are capped");
        }
        if(amount4B > 0) {
            require(wbp.fourStarBurnPoints < 25, "Four star burn points are capped");
        }
        if(amount5B > 0) {
            require(wbp.fiveStarBurnPoints < 10, "Five star burn points are capped");
        }

        wbp.lowStarBurnPoints += amountLB;
        wbp.fourStarBurnPoints += amount4B;
        wbp.fiveStarBurnPoints += amount5B;

        if(wbp.lowStarBurnPoints > 100)
            wbp.lowStarBurnPoints = 100;
        if(wbp.fourStarBurnPoints > 25)
            wbp.fourStarBurnPoints = 25;
        if(wbp.fiveStarBurnPoints > 10)
            wbp.fiveStarBurnPoints = 10;
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

    function getBonusPower(uint256 id) public view noFreshLookup(id) returns (uint24) {
        Weapon storage wep = tokens[id];
        return getBonusPowerForFight(id, wep.level);
    }

    function getBonusPowerForFight(uint256 id, uint8 level) public view noFreshLookup(id) returns (uint24) {
        WeaponBurnPoints storage wbp = burnPoints[id];
        return uint24(lowStarBurnPowerPerPoint.mul(wbp.lowStarBurnPoints)
            .add(fourStarBurnPowerPerPoint.mul(wbp.fourStarBurnPoints))
            .add(fiveStarBurnPowerPerPoint.mul(wbp.fiveStarBurnPoints))
            .add(uint256(15).mul(level))
        );
    }

    function getFightData(uint256 id, uint8 charTrait) public view noFreshLookup(id) returns (int128, int128, uint24, uint8) {
        Weapon storage wep = tokens[id];
        return (
            oneFrac.add(powerMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        wep.stat1 + wep.stat2 + wep.stat3
                    )
            )),//targetMult
            getPowerMultiplierForTrait(wep.properties, wep.stat1, wep.stat2, wep.stat3, charTrait),
            getBonusPowerForFight(id, wep.level),
            getTraitFromProperties(wep.properties)
        );
    }

    function getFightDataAndDrainDurability(uint256 id, uint8 charTrait, uint8 drainAmount) public
        restricted noFreshLookup(id)
    returns (int128, int128, uint24, uint8) {

        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
        require(durabilityPoints >= drainAmount, "Not enough durability!");

        uint64 drainTime = uint64(drainAmount * secondsPerDurability);
        if(durabilityPoints >= maxDurability) { // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(now - getDurabilityMaxWait() + drainTime);
        }
        else {
            durabilityTimestamp[id] = uint64(durabilityTimestamp[id] + drainTime);
        }
        
        Weapon storage wep = tokens[id];
        return (
            oneFrac.add(powerMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        wep.stat1 + wep.stat2 + wep.stat3
                    )
            )),//targetMult
            getPowerMultiplierForTrait(wep.properties, wep.stat1, wep.stat2, wep.stat3, charTrait),
            getBonusPowerForFight(id, wep.level),
            getTraitFromProperties(wep.properties)
        );
    }

    function drainDurability(uint256 id, uint8 amount) public restricted {
        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
        require(durabilityPoints >= amount, "Not enough durability!");

        uint64 drainTime = uint64(amount * secondsPerDurability);
        if(durabilityPoints >= maxDurability) { // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(now - getDurabilityMaxWait() + drainTime);
        }
        else {
            durabilityTimestamp[id] = uint64(durabilityTimestamp[id] + drainTime);
        }
    }

    function setBurnPointMultiplier(uint256 multiplier) public restricted {
        require(multiplier >= 1, "BurnPointMultiplier too low");
        require(multiplier <= 5, "BurnPointMultiplier too high");
        burnPointMultiplier = multiplier;
    }
    function setLowStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        require(powerPerBurnPoint >= 10, "LowStarBurnPowerPerPoint too low");
        require(powerPerBurnPoint <= 20, "LowStarBurnPowerPerPoint too high");
        lowStarBurnPowerPerPoint = powerPerBurnPoint;
    }
    function setFourStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        require(powerPerBurnPoint >= 25, "FourStarBurnPowerPerPoint too low");
        require(powerPerBurnPoint <= 35, "FourStarBurnPowerPerPoint too high");
        fourStarBurnPowerPerPoint = powerPerBurnPoint;
    }
    function setFiveStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        require(powerPerBurnPoint >= 40, "FiveStarBurnPowerPerPoint too low");
        require(powerPerBurnPoint <= 80, "FiveStarBurnPowerPerPoint too high");
        fiveStarBurnPowerPerPoint = powerPerBurnPoint;
    }

    function getDurabilityTimestamp(uint256 id) public view returns (uint64) {
        return durabilityTimestamp[id];
    }

    function setDurabilityTimestamp(uint256 id, uint64 timestamp) public restricted {
        durabilityTimestamp[id] = timestamp;
    }

    function getDurabilityPoints(uint256 id) public view returns (uint8) {
        return getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
    }

    function getDurabilityPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerDurability;
        if(points > maxDurability) {
            points = maxDurability;
        }
        return uint8(points);
    }

    function isDurabilityFull(uint256 id) public view returns (bool) {
        return getDurabilityPoints(id) >= maxDurability;
    }

    function getDurabilityMaxWait() public pure returns (uint64) {
        return uint64(maxDurability * secondsPerDurability);
    }
}
