pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStakeFromGame.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IPriceOracle.sol";
import "./characters.sol";
import "./Promos.sol";
import "./weapons.sol";
import "./util.sol";

contract CryptoBlades is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint64;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    int128 public constant REWARDS_CLAIM_TAX_MAX = 2767011611056432742; // = ~0.15 = ~15%
    uint256 public constant REWARDS_CLAIM_TAX_DURATION = 15 days;

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
        fightRewardBaseline = ABDKMath64x64.divu(1, 100);//0.01 usd;
        fightRewardGasOffset = ABDKMath64x64.divu(8, 10);//0.8 usd;
        mintWeaponFee = ABDKMath64x64.divu(3, 1);//3 usd;
        reforgeWeaponFee = ABDKMath64x64.divu(5, 10);//0.5 usd;
    }

    function migrateTo_1ee400a() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        fightXpGain = 32;
    }

    function migrateTo_aa9da90() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        oneFrac = ABDKMath64x64.fromUInt(1);
        fightTraitBonus = ABDKMath64x64.divu(75, 1000);
    }

    function migrateTo_ef994e2(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        promos = _promos;
    }

    function migrateTo_23b3a8b(IStakeFromGame _stakeFromGame) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        stakeFromGameImpl = _stakeFromGame;
    }

    function migrateTo_7dd2a56() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        // numbers given for the curves were $4.3-aligned so they need to be multiplied
        // additional accuracy may be in order for the setter functions for these
        fightRewardGasOffset = ABDKMath64x64.divu(23177, 100000); // 0.0539 x 4.3
        fightRewardBaseline = ABDKMath64x64.divu(344, 1000); // 0.08 x 4.3
    }

    function migrateTo_5e833b0() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        durabilityCostFight = 1;
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

    mapping(address => uint256) public inGameOnlyFunds;
    uint256 public totalInGameOnlyFunds;

    Promos public promos;

    mapping(address => uint256) private _rewardsClaimTaxTimerStart;

    IStakeFromGame public stakeFromGameImpl;

    uint8 durabilityCostFight;

    event FightOutcome(address indexed owner, uint256 indexed character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll, uint16 xpGain, uint256 skillGain);
    event InGameOnlyFundsGiven(address indexed to, uint256 skillAmount);

    function recoverSkill(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        skillToken.transfer(msg.sender, amount);
    }

    function getSkillToSubtract(uint256 _inGameOnlyFunds, uint256 _tokenRewards, uint256 _skillNeeded)
        public
        pure
        returns (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) {

        if(_skillNeeded <= _inGameOnlyFunds) {
            return (_skillNeeded, 0, 0);
        }

        _skillNeeded -= _inGameOnlyFunds;

        if(_skillNeeded <= _tokenRewards) {
            return (_inGameOnlyFunds, _skillNeeded, 0);
        }

        _skillNeeded -= _tokenRewards;

        return (_inGameOnlyFunds, _tokenRewards, _skillNeeded);
    }

    function getSkillNeededFromUserWallet(address playerAddress, uint256 skillNeeded)
        public
        view
        returns (uint256 skillNeededFromUserWallet) {

        (,, skillNeededFromUserWallet) = getSkillToSubtract(
            inGameOnlyFunds[playerAddress],
            tokenRewards[playerAddress],
            skillNeeded
        );
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

    function unpackFightData(uint96 playerData)
        public pure returns (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) {

        charTrait = uint8(playerData & 0xFF);
        basePowerLevel = uint24((playerData >> 8) & 0xFFFFFF);
        timestamp = uint64((playerData >> 32) & 0xFFFFFFFFFFFFFFFF);
    }

    function fight(uint256 char, uint256 wep, uint32 target) external
            doesNotHaveMoreThanMaxCharacters
            oncePerBlock(msg.sender)
            isCharacterOwner(char)
            isWeaponOwner(wep) {

        (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) =
            unpackFightData(characters.getFightDataAndDrainStamina(char, staminaCostFight));

        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightData(wep, charTrait);

        weapons.drainDurability(wep, durabilityCostFight);

        _verifyFight(
            basePowerLevel,
            weaponMultTarget,
            weaponBonusPower,
            timestamp,
            target
        );
        performFight(
            char,
            wep,
            getPlayerPower(basePowerLevel, weaponMultFight, weaponBonusPower),
            uint24(charTrait | (uint24(weaponTrait) << 8) | (target & 0xFF000000) >> 8),
            uint24(target & 0xFFFFFF)
        );
    }

    function _verifyFight(
        uint24 basePowerLevel,
        int128 weaponMultTarget,
        uint24 weaponBonusPower,
        uint64 timestamp,
        uint32 target
    ) internal view {
        verifyFight(
            basePowerLevel,
            weaponMultTarget,
            weaponBonusPower,
            timestamp,
            getCurrentHour(),
            target
        );
    }

    function verifyFight(
        uint24 playerBasePower,
        int128 wepMultiplier,
        uint24 wepBonusPower,
        uint64 staminaTimestamp,
        uint256 hour,
        uint32 target
    ) public pure {

        uint32[4] memory targets = getTargetsInternal(
            getPlayerPower(playerBasePower, wepMultiplier, wepBonusPower),
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

    function performFight(
        uint256 char,
        uint256 wep,
        uint24 playerFightPower,
        uint24 traitsCWE, // could fit into uint8 since each trait is only stored on 2 bits (TODO)
        uint24 targetPower
    ) private {
        uint256 seed = randoms.getRandomSeed(msg.sender);
        uint24 playerRoll = getPlayerPowerRoll(playerFightPower,traitsCWE,seed);
        uint24 monsterRoll = getMonsterPowerRoll(targetPower, RandomUtil.combineSeeds(seed,1));

        uint16 xp = getXpGainForFight(playerFightPower, targetPower);
        uint256 tokens = usdToSkill(getTokenGainForFight(targetPower));

        if(playerRoll < monsterRoll) {
            tokens = 0;
            xp = 0;
        }

        if(tokenRewards[msg.sender] == 0 && tokens > 0) {
            _startRewardsClaimTaxTimer(msg.sender);
        }

        // this may seem dumb but we want to avoid guessing the outcome based on gas estimates!
        tokenRewards[msg.sender] += tokens;
        xpRewards[char] += xp;

        emit FightOutcome(msg.sender, char, wep, (targetPower | ((uint32(traitsCWE) << 8) & 0xFF000000)), playerRoll, monsterRoll, xp, tokens);
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight(uint24 monsterPower) internal view returns (int128) {
        return fightRewardGasOffset.add(
            fightRewardBaseline.mul(
                ABDKMath64x64.sqrt(
                    // Performance optimization: 1000 = getPowerAtLevel(0)
                    ABDKMath64x64.divu(monsterPower, 1000)
                )
            )
        );
    }

    function getXpGainForFight(uint24 playerPower, uint24 monsterPower) internal view returns (uint16) {
        return uint16(ABDKMath64x64.divu(monsterPower, playerPower).mulu(fightXpGain));
    }

    function getPlayerPowerRoll(
        uint24 playerFightPower,
        uint24 traitsCWE,
        uint256 seed
    ) internal view returns(uint24) {

        uint256 playerPower = RandomUtil.plusMinus10PercentSeeded(playerFightPower,seed);
        return uint24(getPlayerTraitBonusAgainst(traitsCWE).mulu(playerPower));
    }

    function getMonsterPowerRoll(uint24 monsterPower, uint256 seed) internal pure returns(uint24) {
        // roll for fights
        return uint24(RandomUtil.plusMinus10PercentSeeded(monsterPower, seed));
    }

    function getPlayerPower(
        uint24 basePower,
        int128 weaponMultiplier,
        uint24 bonusPower
    ) public pure returns(uint24) {
        return uint24(weaponMultiplier.mulu(basePower).add(bonusPower));
    }

    function getPlayerTraitBonusAgainst(uint24 traitsCWE) public view returns (int128) {
        int128 traitBonus = oneFrac;
        uint8 characterTrait = uint8(traitsCWE & 0xFF);
        if(characterTrait == (traitsCWE >> 8) & 0xFF/*wepTrait*/) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        if(isTraitEffectiveAgainst(characterTrait, uint8(traitsCWE >> 16)/*enemy*/)) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        else if(isTraitEffectiveAgainst(uint8(traitsCWE >> 16)/*enemy*/, characterTrait)) {
            traitBonus = traitBonus.sub(fightTraitBonus);
        }
        return traitBonus;
    }

    function getTargets(uint256 char, uint256 wep) public view returns (uint32[4] memory) {
        (int128 weaponMultTarget,,
            uint24 weaponBonusPower,
            ) = weapons.getFightData(wep, characters.getTrait(char));

        return getTargetsInternal(
            getPlayerPower(characters.getPower(char), weaponMultTarget, weaponBonusPower),
            characters.getStaminaTimestamp(char),
            getCurrentHour()
        );
    }

    function getTargetsInternal(uint24 playerPower,
        uint64 staminaTimestamp,
        uint256 currentHour
    ) private pure returns (uint32[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // trait bonuses not accounted for
        // targets expire on the hour

        uint256 baseSeed = RandomUtil.combineSeeds(
            RandomUtil.combineSeeds(staminaTimestamp,
            currentHour),
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

        if(!promos.getBit(msg.sender, promos.BIT_FIRST_CHARACTER()) && characters.balanceOf(msg.sender) == 0) {
            _giveInGameOnlyFundsFromContractBalance(msg.sender, usdToSkill(promos.firstCharacterPromoInGameOnlyFundsGivenInUsd()));
        }

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

        (,, uint256 fromUserWallet) =
            getSkillToSubtract(
                inGameOnlyFunds[msg.sender],
                tokenRewards[msg.sender],
                skillAmount
            );

        require(skillToken.balanceOf(msg.sender) >= fromUserWallet,
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

        (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) =
            getSkillToSubtract(
                inGameOnlyFunds[playerAddress],
                tokenRewards[playerAddress],
                convertedAmount
            );

        // must use requestPayFromPlayer modifier to approve on the initial function!
        totalInGameOnlyFunds = totalInGameOnlyFunds.sub(fromInGameOnlyFunds);
        inGameOnlyFunds[playerAddress] = inGameOnlyFunds[playerAddress].sub(fromInGameOnlyFunds);

        tokenRewards[playerAddress] = tokenRewards[playerAddress].sub(fromTokenRewards);
        skillToken.transferFrom(playerAddress, address(this), fromUserWallet);
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
        require(cents >= 25, "ReforgeWeaponValue too low");
        require(cents <= 100, "ReforgeWeaponValue too high");
        reforgeWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setStaminaCostFight(uint8 points) public restricted {
        require(points >= 20, "StaminaCostFight too low");
        require(points <= 50, "StaminaCostFight too high");
        staminaCostFight = points;
    }

    function setDurabilityCostFight(uint8 points) public restricted {
        durabilityCostFight = points;
    }

    function setFightXpGain(uint256 average) public restricted {
        require(average >= 16, "FightXpGain too low");
        require(average <= 64, "FightXpGain too high");
        fightXpGain = average;
    }

    function setCharacterLimit(uint256 max) public restricted {
        characterLimit = max;
    }

    function giveInGameOnlyFunds(address to, uint256 skillAmount) external restricted {
        totalInGameOnlyFunds = totalInGameOnlyFunds.add(skillAmount);
        inGameOnlyFunds[to] = inGameOnlyFunds[to].add(skillAmount);

        skillToken.transferFrom(msg.sender, address(this), skillAmount);

        emit InGameOnlyFundsGiven(to, skillAmount);
    }

    function _giveInGameOnlyFundsFromContractBalance(address to, uint256 skillAmount) internal {
        totalInGameOnlyFunds = totalInGameOnlyFunds.add(skillAmount);
        inGameOnlyFunds[to] = inGameOnlyFunds[to].add(skillAmount);

        emit InGameOnlyFundsGiven(to, skillAmount);
    }

    function giveInGameOnlyFundsFromContractBalance(address to, uint256 skillAmount) external restricted {
        _giveInGameOnlyFundsFromContractBalance(to, skillAmount);
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
        uint256 _tokenRewards = tokenRewards[msg.sender];
        tokenRewards[msg.sender] = 0;

        uint256 _tokenRewardsToPayOut = _tokenRewards.sub(
            _getRewardsClaimTax(msg.sender).mulu(_tokenRewards)
        );

        // Tax goes to game contract itself, which would mean
        // transferring from the game contract to ...itself.
        // So we don't need to do anything with the tax part of the rewards.

        _payPlayerConverted(msg.sender, _tokenRewardsToPayOut);
    }

    function stakeUnclaimedRewards() external {
        uint256 _tokenRewards = tokenRewards[msg.sender];
        tokenRewards[msg.sender] = 0;

        _giveInGameOnlyFundsFromContractBalance(msg.sender, _tokenRewards / 10);

        skillToken.approve(address(stakeFromGameImpl), _tokenRewards);
        stakeFromGameImpl.stakeFromGame(msg.sender, _tokenRewards);
    }

    function claimXpRewards() public {
        // our characters go to the tavern to rest
        // they meditate on what they've learned
        for(uint256 i = 0; i < characters.balanceOf(msg.sender); i++) {
            uint256 char = characters.tokenOfOwnerByIndex(msg.sender, i);
            uint256 xpRewardsToClaim = xpRewards[char];
            xpRewards[char] = 0;
            if (xpRewardsToClaim > 65535) {
                xpRewardsToClaim = 65535;
            }
            characters.gainXp(char, uint16(xpRewardsToClaim));
        }
    }

    function getTokenRewards() public view returns (uint256) {
        return tokenRewards[msg.sender];
    }

    function getXpRewards(uint256 char) public view returns (uint256) {
        return xpRewards[char];
    }

    function getTokenRewardsFor(address wallet) public view returns (uint256) {
        return tokenRewards[wallet];
    }

    function getTotalSkillOwnedBy(address wallet) public view returns (uint256) {
        return inGameOnlyFunds[wallet] + getTokenRewardsFor(wallet) + skillToken.balanceOf(wallet);
    }

    function _getRewardsClaimTax(address playerAddress) internal view returns (int128) {
        assert(_rewardsClaimTaxTimerStart[playerAddress] <= block.timestamp);

        uint256 rewardsClaimTaxTimerEnd = _rewardsClaimTaxTimerStart[playerAddress].add(REWARDS_CLAIM_TAX_DURATION);

        (, uint256 durationUntilNoTax) = rewardsClaimTaxTimerEnd.trySub(block.timestamp);

        assert(0 <= durationUntilNoTax && durationUntilNoTax <= REWARDS_CLAIM_TAX_DURATION);

        int128 frac = ABDKMath64x64.divu(durationUntilNoTax, REWARDS_CLAIM_TAX_DURATION);

        return REWARDS_CLAIM_TAX_MAX.mul(frac);
    }

    function getOwnRewardsClaimTax() public view returns (int128) {
        return _getRewardsClaimTax(msg.sender);
    }

    function _startRewardsClaimTaxTimer(address playerAddress) internal {
        _rewardsClaimTaxTimerStart[playerAddress] = block.timestamp;
    }

}