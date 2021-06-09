// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
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
        staminaCostFight = 20;
        mintCharacterFee = ABDKMath64x64.divu(10, 1);//10 usd;
        refillStaminaFee = ABDKMath64x64.divu(5, 1);//5 usd;
        fightRewardBaseline = ABDKMath64x64.divu(1, 100);//0.01 usd;
        fightRewardGasOffset = ABDKMath64x64.divu(8, 10);//0.8 usd;
        mintWeaponFee = ABDKMath64x64.divu(3, 1);//3 usd;
        reforgeWeaponFee = ABDKMath64x64.divu(5, 10);//0.5 usd;
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
            isWeaponOwner(wep)
            isTargetValid(char, wep, target) {
        performFight(msg.sender, char, wep, target);
    }

    function performFight(address user, uint256 char, uint256 wep, uint32 target) private {
        require(characters.drainStamina(char, staminaCostFight), "Not enough stamina!");

        uint256 seed = randoms.getRandomSeed(user);
        uint24 playerRoll = getPlayerPowerRoll(char, wep, uint8((target >> 24) & 0xFF)/*monster trait*/, seed);
        uint24 monsterRoll = getMonsterPowerRoll(getMonsterPower(target), RandomUtil.combineSeeds(seed,1));

        uint16 xp = 0;
        int128 tokens = 0;
        uint256 roll = seed % 10;

        if(playerRoll >= monsterRoll) {
            xp = getXpGainForFight(char, wep, target);
            tokens = getTokenGainForFight(target);
            characters.gainXp(char, xp);
            if(roll <= 1) {
                weapons.mint(characters.ownerOf(char), seed, true); // adds a 10% chance of rolling for an NFT on a win with half the star odds as a normal mint.
             }  
            _payPlayer(characters.ownerOf(char), tokens);
        }
        else{
            xp = (getXpGainForFight(char, wep, target) / 2); // 1/2 the XP reward for losing the fight.
            tokens = (getTokenGainForFight(target) / 3); // 1/3 the winnings for losing - to ease the pain.
            characters.gainXp(char, xp);
            _payPlayer(characters.ownerOf(char), tokens);
        }
        emit FightOutcome(characters.ownerOf(char), char, wep, target, playerRoll, monsterRoll, xp, usdToSkill(tokens));
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight(uint32 target) internal view returns (int128) {
        uint256 monsterPower = uint256(getMonsterPower(target));
        return ABDKMath64x64.add(
            ABDKMath64x64.divu(monsterPower, characters.getPowerAtLevel(0)).mul(fightRewardBaseline),
            fightRewardGasOffset
        );
    }

    function getXpGainForFight(uint256 char, uint256 wep, uint32 target) internal view returns (uint16) {
        int128 basePowerDifference = ABDKMath64x64.divu(getMonsterPower(target), getPlayerPower(char, wep));
        // base XP gain is 16 for an equal fight
        return uint16(basePowerDifference.mulu(16));
    }

    function getPlayerPowerRoll(uint256 char, uint256 wep, uint8 monsterTrait, uint256 seed) internal view returns(uint24) {
        // roll for fights, non deterministic
        uint256 playerPower = getPlayerFinalPower(char, wep);
        playerPower = RandomUtil.plusMinus10PercentSeeded(playerPower, seed);

        return uint24(getPlayerTraitBonusAgainst(characters.getTrait(char), weapons.getTrait(wep), monsterTrait).mulu(playerPower));
    }

    function getMonsterPowerRoll(uint24 monsterPower, uint256 seed) internal pure returns(uint24) {
        // roll for fights, non deterministic
        return uint24(RandomUtil.plusMinus10PercentSeeded(monsterPower, seed));
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

    function getPlayerTraitBonusAgainst(uint8 characterTrait, uint8 weaponTrait, uint8 monsterTrait) public pure returns(int128) {
        int128 traitBonus = ABDKMath64x64.fromUInt(1);
        int128 oneBonus = ABDKMath64x64.divu(75, 1000);
        if(characterTrait == weaponTrait) {
            traitBonus = traitBonus.add(oneBonus);
        }
        if(isTraitEffectiveAgainst(characterTrait, monsterTrait)) {
            traitBonus = traitBonus.add(oneBonus);
        }
        else if(isTraitWeakAgainst(characterTrait, monsterTrait)) {
            traitBonus = traitBonus.sub(oneBonus);
        }
        return traitBonus;
    }

    function getTargets(uint256 char, uint256 wep) public view returns (uint32[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // trait bonuses not accounted for
        // targets expire on the hour
        uint24 playerPower = getPlayerPower(char, wep);

        uint256 baseSeed = RandomUtil.combineSeeds(
            RandomUtil.combineSeeds(characters.getStaminaTimestamp(char), block.timestamp),
            playerPower
        );

        uint32[4] memory targets;
        for(uint i = 0; i < targets.length; i++) {
            // we alter seed per-index or they would be all the same
            uint256 indexSeed = RandomUtil.combineSeeds(baseSeed, i);
            uint24 monsterPower = uint24(RandomUtil.plusMinus10PercentSeeded(playerPower, indexSeed));
            uint256 monsterTrait = indexSeed % 4;
            targets[i] = monsterPower | (uint32(monsterTrait) << 24);
        }

        return targets;
    }

    function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        if(attacker == 0 && defender == 1) {
            return true;
        }
        if(attacker == 1 && defender == 2) {
            return true;
        }
        if(attacker == 2 && defender == 3) {
            return true;
        }
        if(attacker == 3 && defender == 0) {
            return true;
        }
        return false;
    }

    function isTraitWeakAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        if(attacker == 1 && defender == 0) {
            return true;
        }
        if(attacker == 2 && defender == 1) {
            return true;
        }
        if(attacker == 3 && defender == 2) {
            return true;
        }
        if(attacker == 0 && defender == 3) {
            return true;
        }
        return false;
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

    function mintWeapon() public oncePerBlock(msg.sender) requestPayFromPlayer(mintWeaponFee) {
        _payContract(msg.sender, mintWeaponFee);

        uint256 seed = randoms.getRandomSeed(msg.sender);
        weapons.mint(msg.sender, seed, false);
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
        require(skillToken.balanceOf(msg.sender) >= skillAmount,
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

    function setCharacterLimit(uint256 max) public restricted {
        characterLimit = max;
    }

    function usdToSkill(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleSkillPerUsd.currentPrice());
    }
}