pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IPriceOracle.sol";
import "./characters.sol";
import "./weapons.sol";
import "./util.sol";

contract CryptoBlades is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint64;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    Characters public characters;
    Weapons public weapons;
    IERC20 public skillToken;//0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab;
    IPriceOracle public priceOracleSkillPerUsd;
    IRandoms public randoms;

    function initialize(IERC20 _skillToken, Characters _characters, Weapons _weapons, IPriceOracle _priceOracleSkillPerUsd, IRandoms _randoms) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        skillToken = _skillToken;
        characters = _characters;
        weapons = _weapons;
        priceOracleSkillPerUsd = _priceOracleSkillPerUsd;
        randoms = _randoms;

        characterLimit = 4;
        staminaCostFight = 40;
        mintCharacterFee = ABDKMath64x64.divu(10, 1);//10 usd;
        refillStaminaFee = ABDKMath64x64.divu(5, 1);//5 usd;
        fightRewardBaseline = ABDKMath64x64.divu(1, 100);//0.01 usd;
        fightRewardGasOffset = ABDKMath64x64.divu(8, 10);//0.8 usd;
        mintWeaponFee = ABDKMath64x64.divu(3, 1);//3 usd;
        reforgeWeaponFee = ABDKMath64x64.divu(5, 10);//0.5 usd;

        oneFrac = ABDKMath64x64.fromUInt(1);
        fightTraitBonus = ABDKMath64x64.divu(75, 1000);
    }

    function migrateTo_1ee400a() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        fightXpGain = 32;
    }

    // config vars
    uint characterLimit;
    uint8 staminaCostFight;

    // prices & payouts are in USD, with 4 decimals of accuracy in 64.64 fixed point format
    int128 public mintCharacterFee;
    //int128 public rerollTraitFee;
    //int128 public rerollCosmeticsFee;
    int128 public refillStaminaFee;
    // lvl 1 player power could be anywhere between ~909 to 1666
    // cents per fight multiplied by monster power divided by 1000 (lv1 power)
    int128 public fightRewardBaseline;
    int128 public fightRewardGasOffset;

    int128 public mintWeaponFee;
    int128 public reforgeWeaponFee;

    uint256 nonce;

    mapping(address => uint256) lastBlockNumberCalled;

    uint256 public fightXpGain; // multiplied based on power differences

    mapping(address => uint256) tokenRewards; // user adress : skill wei
    mapping(uint256 => uint256) xpRewards; // character id : xp
    
    int128 public oneFrac; // 1.0
    int128 public fightTraitBonus; // 7.5%

    event FightOutcome(address indexed owner, uint256 indexed character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll, uint16 xpGain, uint256 skillGain);

    function recoverSkill(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        skillToken.transfer(msg.sender, amount);
    }

    function getMyCharacters() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](characters.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = characters.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }

    function getMyWeapons() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](weapons.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = weapons.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }

    function fight(uint256 char, uint256 wep, uint32 target) external
            doesNotHaveMoreThanMaxCharacters
            oncePerBlock(msg.sender)
            isCharacterOwner(char)
            isWeaponOwner(wep) {
        uint96 playerData = characters.getFightDataAndDrainStamina(char, staminaCostFight);
        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightData(wep, uint8(playerData & 0xFF)/*charTrait*/);

        verifyFight(
            uint24((playerData >> 8) & 0xFFFFFF), // playerBasePower
            weaponMultTarget,
            weaponBonusPower,
            uint64((playerData >> 32) & 0xFFFFFFFFFFFFFFFF), // staminaTimestamp
            getCurrentHour(),
            target
        );
        performFightNew(
            msg.sender,
            char,
            wep,
            getPlayerPower2(uint24((playerData >> 8) & 0xFFFFFF), weaponMultFight, weaponBonusPower),
            uint8((playerData & 0xFF/*charTrait*/) | uint24(weaponTrait << 8) | uint24((target >> 24) & 0xFF)),
            uint24(target & 0xFFFFFF)
        );
    }

    /*function testTimestamp(uint256 char) public view returns(uint64) {
        uint96 playerData = characters.getFightDataAndDrainStamina(char, 0);
        return uint64((playerData >> 32) & 0xFFFFFFFFFFFFFFFF);
    }

    function testBasePower(uint256 char) public view returns(uint24) {
        uint96 playerData = characters.getFightDataAndDrainStamina(char, 0);
        return uint24((playerData >> 8) & 0xFFFFFF);
    }

    function testMultTarget(uint256 char, uint256 wep) public view returns (int128) {
        uint96 playerData = characters.getFightDataAndDrainStamina(char, 0);
        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightData(wep, uint8(playerData & 0xFF));
        return weaponMultTarget;
    }

    function testMultFight(uint256 char, uint256 wep) public view returns (int128) {
        uint96 playerData = characters.getFightDataAndDrainStamina(char, 0);
        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightData(wep, uint8(playerData & 0xFF));
        return weaponMultFight;
    }

    function testPower2(uint256 char, uint256 wep) public view returns(uint24) {
        return getPlayerPower2(testBasePower(char), testMultTarget(char, wep), 0);
    }

    function testTargets(uint256 wep, uint256 char) public view returns(uint32[4] memory) {
        
        uint32[4] memory targets = getTargetsInternal(
            getPlayerPower2(testBasePower(char), testMultTarget(char, wep), 0),
            testTimestamp(char),
            getCurrentHour()
        );
        return targets;
    }*/

    function verifyFight(
        uint24 playerBasePower,
        int128 wepMultiplier,
        uint24 wepBonusPower,
        uint64 staminaTimestamp,
        uint256 hour,
        uint32 target
    ) public pure {
        
        uint32[4] memory targets = getTargetsInternal(
            getPlayerPower2(playerBasePower, wepMultiplier, wepBonusPower),
            staminaTimestamp,
            hour
        );
        bool foundMatch = false;
        for(uint i = 0; i < targets.length; i++) {
            if(targets[i] == target) {
                foundMatch = true;
                i = targets.length;
            }
        }
        require(foundMatch, "Target invalid");
    }

    function performFightNew(
        address user,
        uint256 char,
        uint256 wep,
        uint24 playerFightPower,
        uint24 traitsCWE,
        uint24 targetPower
    ) public {
        uint256 seed = randoms.getRandomSeed(user);
        uint24 playerRoll = getPlayerPowerRoll2(playerFightPower,traitsCWE,seed);
        uint24 monsterRoll = getMonsterPowerRoll(targetPower, RandomUtil.combineSeeds(seed,1));

        uint16 xp = getXpGainForFight2(playerFightPower, targetPower); // could hardcode to 16 for 12k gas save
        uint256 tokens = usdToSkill(getTokenGainForFight2(targetPower));

        if(playerRoll >= monsterRoll) {
            tokenRewards[user] = tokenRewards[user].add(tokens);
            xpRewards[char] = SafeMath.add(xpRewards[char], xp);
        }
        else {
            // this may seem dumb but we want to avoid guessing the outcome based on gas estimates!
            tokenRewards[user] = tokenRewards[user].add(0);
            xpRewards[char] = SafeMath.add(xpRewards[char], 0);
        }

        emit FightOutcome(user, char, wep, (targetPower | ((traitsCWE << 8) & 0xFF0000)), playerRoll, monsterRoll, xp, tokens);
    }

    function performFight(address user, uint256 char, uint256 wep, uint32 target) public {

        uint256 seed = randoms.getRandomSeed(user);
        uint24 playerRoll = getPlayerPowerRoll(char, wep, uint8((target >> 24) & 0xFF)/*monster trait*/, seed);
        uint24 monsterRoll = getMonsterPowerRoll(getMonsterPower(target), RandomUtil.combineSeeds(seed,1));

        uint16 xp = getXpGainForFight(char, wep, target); // could hardcode to 16 for 12k gas save
        uint256 tokens = usdToSkill(getTokenGainForFight(target));

        if(playerRoll >= monsterRoll) {
            tokenRewards[user] = tokenRewards[user].add(tokens);
            xpRewards[char] = SafeMath.add(xpRewards[char], xp);
        }
        else {
            // this may seem dumb but we want to avoid guessing the outcome based on gas estimates!
            tokenRewards[user] = tokenRewards[user].add(0);
            xpRewards[char] = SafeMath.add(xpRewards[char], 0);
        }

        emit FightOutcome(characters.ownerOf(char), char, wep, target, playerRoll, monsterRoll, xp, tokens);
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight2(uint24 monsterPower) public view returns (int128) {
        return ABDKMath64x64.add(
            ABDKMath64x64.divu(monsterPower, 1000).mul(fightRewardBaseline),
            fightRewardGasOffset
        );
    }

    function getTokenGainForFight(uint32 target) public view returns (int128) {
        uint256 monsterPower = uint256(getMonsterPower(target));
        return ABDKMath64x64.add(
            ABDKMath64x64.divu(monsterPower, characters.getPowerAtLevel(0)).mul(fightRewardBaseline),
            fightRewardGasOffset
        );
    }

    function getXpGainForFight2(uint24 playerPower, uint24 monsterPower) public view returns (uint16) {
        return uint16(ABDKMath64x64.divu(monsterPower, playerPower).mulu(fightXpGain));
    }

    function getXpGainForFight(uint256 char, uint256 wep, uint32 target) public view returns (uint16) {
        int128 basePowerDifference = ABDKMath64x64.divu(getMonsterPower(target), getPlayerPower(char, wep));
        // base XP gain is "fightXpGain" for an equal fight
        return uint16(basePowerDifference.mulu(fightXpGain));
    }

    function getPlayerPowerRoll2(
        uint24 playerFightPower,
        uint24 traitsCWE,
        uint256 seed
    ) public view returns(uint24) {

        uint256 playerPower = RandomUtil.plusMinus10PercentSeeded(playerFightPower,seed);
        return uint24(getPlayerTraitBonusAgainst2(traitsCWE).mulu(playerPower));
    }

    function getPlayerPowerRoll(uint256 char, uint256 wep, uint8 monsterTrait, uint256 seed) public view returns(uint24) {
        // roll for fights, non deterministic
        uint256 playerPower = getPlayerFinalPower(char, wep);
        playerPower = RandomUtil.plusMinus10PercentSeeded(playerPower, seed);

        return uint24(getPlayerTraitBonusAgainst(characters.getTrait(char), weapons.getTrait(wep), monsterTrait).mulu(playerPower));
    }

    function getMonsterPowerRoll(uint24 monsterPower, uint256 seed) public pure returns(uint24) {
        // roll for fights, non deterministic
        return uint24(RandomUtil.plusMinus10PercentSeeded(monsterPower, seed));
    }

    function getPlayerPower2(
        uint24 basePower,
        int128 weaponMultiplier,
        uint24 bonusPower
    ) public pure returns(uint24) {
        // does not account for trait matches
        return uint24(weaponMultiplier.mulu(basePower).add(bonusPower));
    }

    function getPlayerPower(uint256 char, uint256 wep) public view returns (uint24) {
        // does not account for trait matches
        return uint24(
            ABDKMath64x64.fromUInt(characters.getPower(char))
                .mul(weapons.getPowerMultiplier(wep))
                .toUInt().add(weapons.getBonusPower(wep))
        );
    }

    function getPlayerFinalPower(uint256 char, uint256 wep) public view returns (uint24) {
        // accounts for trait matches
        return uint24(
            ABDKMath64x64.fromUInt(characters.getPower(char))
                .mul(weapons.getPowerMultiplierForTrait(wep, characters.getTrait(char)))
                .toUInt().add(weapons.getBonusPower(wep))
        );
    }

    function getPlayerTraitBonusAgainst2(uint24 traitsCWE) public view returns (int128) {
        int128 traitBonus = oneFrac;
        uint8 characterTrait = uint8(traitsCWE & 0xFF);
        if(characterTrait == uint8((traitsCWE >> 8) & 0xFF)/*wepTrait*/) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        if(isTraitEffectiveAgainst(characterTrait, uint8((traitsCWE >> 16) & 0xFF))) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        else if(isTraitEffectiveAgainst(uint8((traitsCWE >> 16) & 0xFF), characterTrait)) {
            traitBonus = traitBonus.sub(fightTraitBonus);
        }
        return traitBonus;
    }

    function getPlayerTraitBonusAgainst(uint8 characterTrait, uint8 weaponTrait, uint8 monsterTrait) public pure returns(int128) {
        int128 traitBonus = ABDKMath64x64.fromUInt(1);
        int128 oneBonus = ABDKMath64x64.divu(75, 1000);
        if(characterTrait == weaponTrait) {
            traitBonus = traitBonus.add(oneBonus);
        }
        if(isTraitEffectiveAgainst(characterTrait, monsterTrait)) {
            traitBonus = traitBonus.add(oneBonus);
        }
        else if(isTraitEffectiveAgainst(monsterTrait, characterTrait)) {
            traitBonus = traitBonus.sub(oneBonus);
        }
        return traitBonus;
    }

    function getTargets(uint256 char, uint256 wep) public view returns (uint32[4] memory) {
        return getTargetsInternal(getPlayerPower(char, wep), characters.getStaminaTimestamp(char), getCurrentHour());
    }

    function getTargetsInternal(uint24 playerPower,
        uint64 staminaTimestamp,
        uint256 currentHour
    ) public pure returns (uint32[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // trait bonuses not accounted for
        // targets expire on the hour
        //uint24 playerPower = getPlayerPower(char, wep);

        uint256 baseSeed = RandomUtil.combineSeeds(
            RandomUtil.combineSeeds(staminaTimestamp/*characters.getStaminaTimestamp(char)*/,
            currentHour/*getCurrentHour()*/),
            playerPower
        );

        uint32[4] memory targets;
        for(uint i = 0; i < targets.length; i++) {
            // we alter seed per-index or they would be all the same
            uint256 indexSeed = RandomUtil.combineSeeds(baseSeed, i);
            targets[i] = uint32(
                RandomUtil.plusMinus10PercentSeeded(playerPower, indexSeed) // power
                | (uint32(indexSeed % 4) << 24) // trait
            );
        }

        return targets;
    }

    function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        return (((attacker + 1) % 4) == defender); // Thanks to Tourist
    }

    function mintCharacter() public doesNotHaveMoreThanMaxCharacters oncePerBlock(msg.sender) requestPayFromPlayer(mintCharacterFee) {
        require(characters.balanceOf(msg.sender) < characterLimit,
            string(abi.encodePacked("You can only have ",characterLimit," characters!")));
        _payContract(msg.sender, mintCharacterFee);

        uint256 seed = randoms.getRandomSeed(msg.sender);
        characters.mint(msg.sender, seed);

        // first weapon free with a character mint, max 1 star
        if(weapons.balanceOf(msg.sender) == 0) {
            weapons.performMintWeapon(msg.sender,
                weapons.getRandomProperties(0, RandomUtil.combineSeeds(seed,100)),
                weapons.getRandomStat(4, 200, seed, 101),
                0, // stat2
                0, // stat3
                RandomUtil.combineSeeds(seed,102)
            );
        }
    }

    function mintWeapon() public doesNotHaveMoreThanMaxCharacters oncePerBlock(msg.sender) requestPayFromPlayer(mintWeaponFee) {
        _payContract(msg.sender, mintWeaponFee);

        uint256 seed = randoms.getRandomSeed(msg.sender);
        weapons.mint(msg.sender, seed);
    }

    function fillStamina(uint256 character) public doesNotHaveMoreThanMaxCharacters isCharacterOwner(character) requestPayFromPlayer(refillStaminaFee) {
        require(characters.isStaminaFull(character) == false, "Your stamina is already full!");
        _payContract(msg.sender, refillStaminaFee);
        characters.setStaminaTimestamp(character,
            uint64(
                characters.getStaminaTimestamp(character)
                    .sub(characters.getStaminaMaxWait())
            )
        );
    }

    function reforgeWeapon(uint256 reforgeID, uint256 burnID) public
            doesNotHaveMoreThanMaxCharacters
            isWeaponOwner(reforgeID) isWeaponOwner(burnID) requestPayFromPlayer(reforgeWeaponFee) {
        _payContract(msg.sender, reforgeWeaponFee);
        weapons.reforge(reforgeID, burnID);
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        randoms = _newRandoms;
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Missing GAME_ADMIN role");
        _;
    }

    modifier oncePerBlock(address user) {
        require(lastBlockNumberCalled[user] < block.number, "Only callable once per block");
        lastBlockNumberCalled[user] = block.number;
        _;
    }

    modifier isWeaponOwner(uint256 weapon) {
        require(weapons.ownerOf(weapon) == msg.sender, "Not the weapon owner");
        _;
    }

    modifier isCharacterOwner(uint256 character) {
        require(characters.ownerOf(character) == msg.sender, "Not the character owner");
        _;
    }

    modifier doesNotHaveMoreThanMaxCharacters() {
        require(characters.balanceOf(msg.sender) <= characterLimit, "Too many characters owned");
        _;
    }

    modifier isTargetValid(uint256 character, uint256 weapon, uint32 target) {
        bool foundMatch = false;
        uint32[4] memory targets = getTargets(character, weapon);
        for(uint i = 0; i < targets.length; i++) {
            if(targets[i] == target) {
                foundMatch = true;
            }
        }
        require(foundMatch, "Target invalid");
        _;
    }

    modifier requestPayFromPlayer(int128 usdAmount) {
        uint256 skillAmount = usdToSkill(usdAmount);
        require(tokenRewards[msg.sender] >= skillAmount
            || skillToken.balanceOf(msg.sender) >= skillAmount,
            string(abi.encodePacked("Not enough SKILL! Need ",RandomUtil.uint2str(skillAmount))));
        _;
    }

    function payContract(address playerAddress, int128 usdAmount) public restricted {
        _payContract(playerAddress, usdAmount);
    }

    function payContractConverted(address playerAddress, uint256 convertedAmount) public restricted {
        _payContractConverted(playerAddress, convertedAmount);
    }

    function payPlayer(address playerAddress, int128 baseAmount) public restricted {
        _payPlayer(playerAddress, baseAmount);
    }

    function payPlayerConverted(address playerAddress, uint256 convertedAmount) public restricted {
        _payPlayerConverted(playerAddress, convertedAmount);
    }

    function approveContractCharacterFor(uint256 characterID, address playerAddress) public restricted {
        _approveContractCharacterFor(characterID, playerAddress);
    }

    function approveContractWeaponFor(uint256 weaponID, address playerAddress) public restricted {
        _approveContractWeaponFor(weaponID, playerAddress);
    }

    function _payContract(address playerAddress, int128 usdAmount) internal {
        _payContractConverted(playerAddress, usdToSkill(usdAmount));
    }

    function _payContractConverted(address playerAddress, uint256 convertedAmount) internal {
        // must use requestPayFromPlayer modifier to approve on the initial function!
        if(convertedAmount <= tokenRewards[playerAddress])
            tokenRewards[playerAddress] = tokenRewards[playerAddress].sub(convertedAmount);
        else
            skillToken.transferFrom(playerAddress, address(this), convertedAmount);
    }

    function _payPlayer(address playerAddress, int128 baseAmount) internal {
        _payPlayerConverted(playerAddress, usdToSkill(baseAmount));
    }

    function _payPlayerConverted(address playerAddress, uint256 convertedAmount) internal {
        skillToken.transfer(playerAddress, convertedAmount);
    }

    function _approveContractCharacterFor(uint256 characterID, address playerAddress) internal {
        characters.approve(playerAddress, characterID);
    }

    function _approveContractWeaponFor(uint256 weaponID, address playerAddress) internal {
        weapons.approve(playerAddress, weaponID);
    }

    function setCharacterMintValue(uint256 cents) public restricted {
        mintCharacterFee = ABDKMath64x64.divu(cents, 100);
    }

    function setRefillStaminaValue(uint256 cents) public restricted {
        refillStaminaFee = ABDKMath64x64.divu(cents, 100);
    }

    function setFightRewardBaselineValue(uint256 tenthcents) public restricted {
        fightRewardBaseline = ABDKMath64x64.divu(tenthcents, 1000); // !!! THIS TAKES TENTH OF CENTS !!!
    }

    function setFightRewardGasOffsetValue(uint256 cents) public restricted {
        fightRewardGasOffset = ABDKMath64x64.divu(cents, 100);
    }

    function setWeaponMintValue(uint256 cents) public restricted {
        mintWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setReforgeWeaponValue(uint256 cents) public restricted {
        reforgeWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setStaminaCostFight(uint8 points) public restricted {
        staminaCostFight = points;
    }

    function setFightXpGain(uint256 average) public restricted {
        fightXpGain = average;
    }

    function setCharacterLimit(uint256 max) public restricted {
        characterLimit = max;
    }

    function usdToSkill(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleSkillPerUsd.currentPrice());
    }

    function getCurrentHour() public view returns (uint256) {
        // "now" returns unix time since 1970 Jan 1, in seconds
        return now.div(1 hours);
    }

    function claimTokenRewards() public {
        // our characters go to the tavern
        // and the barkeep pays them for the bounties
        _payPlayerConverted(msg.sender, tokenRewards[msg.sender]);
        tokenRewards[msg.sender] = 0;
    }

    function claimXpRewards() public {
        // our characters go to the tavern to rest
        // they meditate on what they've learned
        for(uint256 i = 0; i < characters.balanceOf(msg.sender); i++) {
            uint256 char = characters.tokenOfOwnerByIndex(msg.sender, i);
            if(xpRewards[char] < 65536)
                characters.gainXp(char, uint16(xpRewards[char]));
            else
                characters.gainXp(char, 65535);
            xpRewards[char] = 0;
        }
    }

    function getTokenRewards() public view returns (uint256) {
        return tokenRewards[msg.sender];
    }

    function getXpRewards(uint256 char) public view returns (uint256) {
        return xpRewards[char];
    }

}