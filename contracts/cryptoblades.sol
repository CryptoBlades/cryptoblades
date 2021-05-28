pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IPriceOracle.sol";
import "./characters.sol";
import "./weapons.sol";
import "./util.sol";

contract CryptoBlades is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;

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
        staminaCostFight = 0;
        mintCharacterFee = ABDKMath64x64.divu(10, 1);//10 usd;
        refillStaminaFee = ABDKMath64x64.divu(5, 1);//5 usd;
        fightRewardBaseline = ABDKMath64x64.divu(1, 100);//0.01 usd;
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

    int128 public mintWeaponFee;
    int128 public reforgeWeaponFee;

    uint256 nonce;

    event FightOutcome(address indexed owner, uint256 indexed character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll, uint16 xpGain, uint256 skillGain);

    function giveMeSkill(uint256 amount) public {
        // TODO REMOVE; TEMPORARY FUNCITON TO TEST WITH
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

    function requestRandom() external {
        randoms.getRandomNumber(msg.sender);
    }

    function fight(uint256 char, uint256 wep, uint32 target) external
            isCharacterOwner(char)
            isWeaponOwner(wep)
            isTargetValid(char, wep, target) {
        performFight(msg.sender, char, wep, target);
    }

    function performFight(address user, uint256 char, uint256 wep, uint32 target) private {
        // avg xp gain from a fight is 9 xp

        require(characters.drainStamina(char, staminaCostFight), "Not enough stamina!");

        uint256 seed = randoms.consumeSeed(user);
        uint24 playerRoll = getPlayerPowerRoll(char, wep, uint8((target >> 24) & 0xFF)/*monster trait*/, seed);
        uint24 monsterRoll = getMonsterPowerRoll(getMonsterPower(target), RandomUtil.combineSeeds(seed,1));

        if(playerRoll >= monsterRoll) {
            characters.gainXp(char, getXpGainForFight(char, wep, target));
            _payPlayer(characters.ownerOf(char), getTokenGainForFight(target));
        }
        emit FightOutcome(characters.ownerOf(char), char, wep, target, playerRoll, monsterRoll, getXpGainForFight(char, wep, target), usdToSkill(getTokenGainForFight(target)));
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight(uint32 target) internal view returns (int128) {
        uint256 monsterPower = uint256(getMonsterPower(target));
        return ABDKMath64x64.divu(monsterPower, characters.getPowerAtLevel(0)).mul(fightRewardBaseline);
    }

    function getXpGainForFight(uint256 char, uint256 wep, uint32 target) internal view returns (uint16) {
        int128 basePowerDifference = ABDKMath64x64.divu(getMonsterPower(target), getPlayerPower(char, wep));
        // base XP gain is 16 for an equal fight
        return uint16((basePowerDifference * 16).toUInt());
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
                .toUInt()
        );
    }

    function getPlayerFinalPower(uint256 char, uint256 wep) public view returns (uint24) {
        // accounts for trait matches
        return uint24(
            ABDKMath64x64.fromUInt(characters.getPower(char))
                .mul(
                    weapons.getPowerMultiplierForTrait(wep, characters.getTrait(char))
                )
                .toUInt()
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

        uint[] memory seedArray = new uint[](5);
        seedArray[0] = char;
        seedArray[1] = playerPower;
        seedArray[2] = characters.getXp(char);
        seedArray[3] = characters.getStaminaTimestamp(char);
        seedArray[4] = getCurrentHour();
        uint256 baseSeed = RandomUtil.combineSeeds(seedArray);

        uint32[4] memory targets;
        for(uint i = 0; i < targets.length; i++) {
            // we alter seed per-index or they would be all the same
            uint256 indexSeed = RandomUtil.randomSeeded(RandomUtil.combineSeeds(baseSeed, i));
            uint24 monsterPower = uint24(RandomUtil.plusMinus10PercentSeeded(playerPower, indexSeed));
            uint256 monsterTrait = RandomUtil.randomSeededMinMax(0,3, indexSeed);
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

    function mintCharacter() public requestPayFromPlayer(mintCharacterFee) {
        require(characters.balanceOf(msg.sender) <= characterLimit,
            string(abi.encodePacked("You can only have ",characterLimit," characters!")));
        _payContract(msg.sender, mintCharacterFee);

        uint256 seed = randoms.consumeSeed(msg.sender);
        characters.mint(msg.sender, seed);

        // first weapon free with a character mint, max 1 star
        if(weapons.balanceOf(msg.sender) == 0) {
            weapons.performMintWeapon(msg.sender,
                weapons.getRandomProperties(0, RandomUtil.combineSeeds(seed,100)),
                weapons.getRandomStat(4, 200, seed, 101),
                0, // stat2
                0, // stat3
                weapons.getRandomCosmetic(seed,102), // blade
                weapons.getRandomCosmetic(seed,103), // crossguard
                weapons.getRandomCosmetic(seed,104), // grip
                weapons.getRandomCosmetic(seed,105) // pommel
            );
        }
    }

    function mintWeapon() public requestPayFromPlayer(mintWeaponFee) {
        _payContract(msg.sender, mintWeaponFee);

        uint256 seed = randoms.consumeSeed(msg.sender);
        weapons.mint(msg.sender, seed);
    }

    function fillStamina(uint256 character) public isCharacterOwner(character) requestPayFromPlayer(refillStaminaFee) {
        require(characters.isStaminaFull(character) == false, "Your stamina is already full!");
        _payContract(msg.sender, refillStaminaFee);
        characters.setStaminaTimestamp(character, characters.getStaminaTimestamp(character) - characters.getStaminaMaxWait());
    }

    function reforgeWeapon(uint256 reforgeID, uint256 burnID) public
            isWeaponOwner(reforgeID) isWeaponOwner(burnID) requestPayFromPlayer(reforgeWeaponFee) {

        require(weapons.getLevel(reforgeID) < 127, "Weapons cannot be improved beyond level 128!");
        _payContract(msg.sender, reforgeWeaponFee);

        uint256 seed = randoms.consumeSeed(msg.sender);
        weapons.reforge(reforgeID, burnID, seed);
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Missing GAME_ADMIN role");
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
        skillToken.approve(address(this), convertedAmount);
        skillToken.transferFrom(address(this), playerAddress, convertedAmount);
    }

    function _approveContractCharacterFor(uint256 characterID, address playerAddress) internal {
        characters.approve(playerAddress, characterID);
    }

    function _approveContractWeaponFor(uint256 weaponID, address playerAddress) internal {
        weapons.approve(playerAddress, weaponID);
    }

    function usdToSkill(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleSkillPerUsd.currentPrice());
    }

    function getCurrentHour() public view returns (uint256) {
        // "now" returns unix time since 1970 Jan 1, in seconds
        return now / (1 hours);
    }

}