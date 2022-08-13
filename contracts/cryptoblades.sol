pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IStakeFromGame.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IPriceOracle.sol";
import "./characters.sol";
import "./Promos.sol";
import "./weapons.sol";
import "./util.sol";
import "./common.sol";
import "./Blacksmith.sol";
import "./SpecialWeaponsManager.sol";

contract CryptoBlades is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeERC20 for IERC20;

    struct FightData {
        uint24 playerFightPower;
        uint24 traitsCWE;
        uint24 targetPower;
    }

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    int128 public constant PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT =
        14757395258967641292; // 0.8 in fixed-point 64x64 format

    // Mapped variables (vars[]) keys, one value per key
    // Using small numbers for now to save on contract size (3% for 13 vars vs using uint256(keccak256("name"))!)
    // Can be migrated later via setVars if needed
    uint256 public constant VAR_HOURLY_INCOME = 1;
    uint256 public constant VAR_HOURLY_FIGHTS = 2;
    uint256 public constant VAR_HOURLY_POWER_SUM = 3;
    uint256 public constant VAR_HOURLY_POWER_AVERAGE = 4;
    uint256 public constant VAR_HOURLY_PAY_PER_FIGHT = 5;
    uint256 public constant VAR_HOURLY_TIMESTAMP = 6;
    uint256 public constant VAR_DAILY_MAX_CLAIM = 7;
    uint256 public constant VAR_CLAIM_DEPOSIT_AMOUNT = 8;
    uint256 public constant VAR_PARAM_PAYOUT_INCOME_PERCENT = 9;
    uint256 public constant VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT = 10;
    uint256 public constant VAR_PARAM_DAILY_CLAIM_DEPOSIT_PERCENT = 11;
    uint256 public constant VAR_PARAM_MAX_FIGHT_PAYOUT = 12;
    uint256 public constant VAR_HOURLY_DISTRIBUTION = 13;
    uint256 public constant VAR_UNCLAIMED_SKILL = 14;
    uint256 public constant VAR_HOURLY_MAX_POWER_AVERAGE = 15;
    uint256 public constant VAR_PARAM_HOURLY_MAX_POWER_PERCENT = 16;
    uint256 public constant VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS = 17;
    uint256 public constant VAR_PARAM_HOURLY_PAY_ALLOWANCE = 18;
    uint256 public constant VAR_MINT_WEAPON_FEE_DECREASE_SPEED = 19;
    uint256 public constant VAR_MINT_CHARACTER_FEE_DECREASE_SPEED = 20;
    uint256 public constant VAR_WEAPON_FEE_INCREASE = 21;
    uint256 public constant VAR_CHARACTER_FEE_INCREASE = 22;
    uint256 public constant VAR_MIN_WEAPON_FEE = 23;
    uint256 public constant VAR_MIN_CHARACTER_FEE = 24;
    uint256 public constant VAR_WEAPON_MINT_TIMESTAMP = 25;
    uint256 public constant VAR_CHARACTER_MINT_TIMESTAMP = 26;


    // Mapped user variable(userVars[]) keys, one value per wallet
    uint256 public constant USERVAR_DAILY_CLAIMED_AMOUNT = 10001;
    uint256 public constant USERVAR_CLAIM_TIMESTAMP = 10002;

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

        staminaCostFight = 40;
        mintCharacterFee = ABDKMath64x64.divu(10, 1);//10 usd;
        mintWeaponFee = ABDKMath64x64.divu(3, 1);//3 usd;

        // migrateTo_1ee400a
        fightXpGain = 32;

        // migrateTo_aa9da90
        oneFrac = ABDKMath64x64.fromUInt(1);
        fightTraitBonus = ABDKMath64x64.divu(75, 1000);

        // migrateTo_7dd2a56
        // numbers given for the curves were $4.3-aligned so they need to be multiplied
        // additional accuracy may be in order for the setter functions for these
        fightRewardGasOffset = ABDKMath64x64.divu(23177, 100000); // 0.0539 x 4.3
        fightRewardBaseline = ABDKMath64x64.divu(344, 1000); // 0.08 x 4.3

        // migrateTo_5e833b0
        durabilityCostFight = 1;
    }

    function migrateTo_ef994e2(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        promos = _promos;
    }

    function migrateTo_23b3a8b(IStakeFromGame _stakeFromGame) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        stakeFromGameImpl = _stakeFromGame;
    }

    function migrateTo_801f279() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        burnWeaponFee = ABDKMath64x64.divu(2, 10);//0.2 usd;
        reforgeWeaponWithDustFee = ABDKMath64x64.divu(3, 10);//0.3 usd;

        reforgeWeaponFee = burnWeaponFee + reforgeWeaponWithDustFee;//0.5 usd;
    }

    function migrateTo_60872c8(Blacksmith _blacksmith) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        blacksmith = _blacksmith;
    }

    function migrateTo_6a97bd1() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        rewardsClaimTaxMax = 2767011611056432742; // = ~0.15 = ~15%
        rewardsClaimTaxDuration = 15 days;
    }

    function migrateTo_e1fe97c(SpecialWeaponsManager _swm) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        specialWeaponsManager = _swm;
    }

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    uint characterLimit;
    // config vars
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

    int128 public burnWeaponFee;
    int128 public reforgeWeaponWithDustFee;

    Blacksmith public blacksmith;

    struct MintPayment {
        bytes32 blockHash;
        uint256 blockNumber;
        address nftAddress;
        uint count;
    }

    mapping(address => MintPayment) mintPayments;

    struct MintPaymentSkillDeposited {
        uint256 skillDepositedFromWallet;
        uint256 skillDepositedFromRewards;
        uint256 skillDepositedFromIgo;

        uint256 skillRefundableFromWallet;
        uint256 skillRefundableFromRewards;
        uint256 skillRefundableFromIgo;

        uint256 refundClaimableTimestamp;
    }

    uint256 public totalMintPaymentSkillRefundable;
    mapping(address => MintPaymentSkillDeposited) mintPaymentSkillDepositeds;

    int128 private rewardsClaimTaxMax;
    uint256 private rewardsClaimTaxDuration;

    mapping(uint256 => uint256) public vars;
    mapping(address => mapping(uint256 => uint256)) public userVars;

    SpecialWeaponsManager public specialWeaponsManager;

    event FightOutcome(address indexed owner, uint256 indexed character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll, uint16 xpGain, uint256 skillGain);
    event InGameOnlyFundsGiven(address indexed to, uint256 skillAmount);

    function recoverSkill(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        skillToken.safeTransfer(msg.sender, amount);
    }

    function REWARDS_CLAIM_TAX_MAX() public view returns (int128) {
        return rewardsClaimTaxMax;
    }

    function REWARDS_CLAIM_TAX_DURATION() public view returns (uint256) {
        return rewardsClaimTaxDuration;
    }

    function getSkillToSubtractSingle(uint256 _needed, uint256 _available)
        public
        pure
        returns (uint256 _used, uint256 _remainder) {

        if(_needed <= _available) {
            return (_needed, 0);
        }

        _needed -= _available;

        return (_available, _needed);
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

    function getSkillNeededFromUserWallet(address playerAddress, uint256 skillNeeded, bool allowInGameOnlyFunds)
        public
        view
        returns (uint256 skillNeededFromUserWallet) {

        uint256 inGameOnlyFundsToUse = 0;
        if (allowInGameOnlyFunds) {
            inGameOnlyFundsToUse = inGameOnlyFunds[playerAddress];
        }
        (,, skillNeededFromUserWallet) = getSkillToSubtract(
            inGameOnlyFundsToUse,
            tokenRewards[playerAddress],
            skillNeeded
        );
    }

    function unpackFightData(uint96 playerData)
        public pure returns (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) {

        charTrait = uint8(playerData & 0xFF);
        basePowerLevel = uint24((playerData >> 8) & 0xFFFFFF);
        timestamp = uint64((playerData >> 32) & 0xFFFFFFFFFFFFFFFF);
    }

    function _getFightDataAndDrainStaminaUnpacked(address fighter, uint256 char, uint8 fightMultiplier) private returns(uint8, uint24, uint64) {
        return unpackFightData(characters.getFightDataAndDrainStamina(fighter,
            char, staminaCostFight * fightMultiplier, false, 0));
    }

    function _getFightDataAndDrainDurability(address fighter, uint256 wep, uint8 charTrait, uint8 fightMultiplier) private returns(int128, int128, uint24, uint8) {
        return weapons.getFightDataAndDrainDurability(fighter, wep, charTrait,
            durabilityCostFight * fightMultiplier, false, 0);
    }

    function fight(address fighter, uint256 char, uint256 wep, uint32 target, uint8 fightMultiplier) external
        restricted returns (uint256, uint256) {
        require(fightMultiplier >= 1 && fightMultiplier <= 5);


        (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) =
            _getFightDataAndDrainStaminaUnpacked(fighter, char, fightMultiplier);
        
        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = _getFightDataAndDrainDurability(fighter, wep, charTrait, fightMultiplier);

        // dirty variable reuse to avoid stack limits
        target = grabTarget(
            Common.getPlayerPower(basePowerLevel, weaponMultTarget, weaponBonusPower),
            timestamp,
            target,
            now / 1 hours
        );
    
        FightData memory data = FightData(
            Common.getPlayerPower(basePowerLevel, weaponMultFight, weaponBonusPower),
            uint24(charTrait | (uint24(weaponTrait) << 8) | (target & 0xFF000000) >> 8),
            uint24(target & 0xFFFFFF)
        );

        return performFight(
            fighter,
            char,
            wep,
            data,
            fightMultiplier
        );
    }

    function performFight(
        address fighter,
        uint256 char,
        uint256 wep,
        FightData memory data,
        uint8 fightMultiplier
    ) private returns (uint256 tokens, uint256 expectedTokens) {
        uint256 seed = uint256(keccak256(abi.encodePacked(now, fighter)));
        uint24 playerRoll = getPlayerPowerRoll(data.playerFightPower,data.traitsCWE,seed);
        uint24 monsterRoll = getMonsterPowerRoll(data.targetPower, RandomUtil.combineSeeds(seed,1));

        updateHourlyPayouts(); // maybe only check in trackIncome? (or do via bot)

        uint16 xp = getXpGainForFight(data.playerFightPower, data.targetPower) * fightMultiplier;
        tokens = getTokenGainForFight(data.targetPower, true) * fightMultiplier;
        expectedTokens = tokens;

        if(tokenRewards[fighter] == 0 && tokens > 0) {
            _rewardsClaimTaxTimerStart[fighter] = block.timestamp;
        }

        if (playerRoll < monsterRoll) {
            tokens = 0;
            xp = 0;
        }

        // this may seem dumb but we want to avoid guessing the outcome based on gas estimates!
        tokenRewards[fighter] += tokens;
        vars[VAR_UNCLAIMED_SKILL] += tokens;
        vars[VAR_HOURLY_DISTRIBUTION] -= tokens;
        xpRewards[char] += xp;


        vars[VAR_HOURLY_FIGHTS] += fightMultiplier;
        vars[VAR_HOURLY_POWER_SUM] += data.playerFightPower * fightMultiplier;

        emit FightOutcome(fighter, char, wep, (data.targetPower | ((uint32(data.traitsCWE) << 8) & 0xFF000000)), playerRoll, monsterRoll, xp, tokens);
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight(uint24 monsterPower, bool applyLimit) public view returns (uint256) {
        // monsterPower / avgPower * payPerFight * powerMultiplier
        uint256 amount = ABDKMath64x64.divu(monsterPower, vars[VAR_HOURLY_POWER_AVERAGE])
            .mulu(vars[VAR_HOURLY_PAY_PER_FIGHT]);

        if(amount > vars[VAR_PARAM_MAX_FIGHT_PAYOUT])
            amount = vars[VAR_PARAM_MAX_FIGHT_PAYOUT];
        if(vars[VAR_HOURLY_DISTRIBUTION] < amount * 5 && applyLimit) // the * 5 is a temp measure until we can sync frontend on main
            amount = 0;
        return amount;
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

    function getPlayerTraitBonusAgainst(uint24 traitsCWE) public view returns (int128) {
        int128 traitBonus = oneFrac;
        uint8 characterTrait = uint8(traitsCWE & 0xFF);
        if(characterTrait == (traitsCWE >> 8) & 0xFF/*wepTrait*/) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        if(Common.isTraitEffectiveAgainst(characterTrait, uint8(traitsCWE >> 16)/*enemy*/)) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        else if(Common.isTraitEffectiveAgainst(uint8(traitsCWE >> 16)/*enemy*/, characterTrait)) {
            traitBonus = traitBonus.sub(fightTraitBonus);
        }
        return traitBonus;
    }

    function getTargets(uint256 char, uint256 wep) public view returns (uint32[4] memory) {
        // this is a frontend function
        (int128 weaponMultTarget,,
            uint24 weaponBonusPower,
            ) = weapons.getFightData(wep, characters.getTrait(char));

        return getTargetsInternal(
            Common.getPlayerPower(uint24(characters.getTotalPower(char)), weaponMultTarget, weaponBonusPower),
            characters.getStaminaTimestamp(char),
            now / 1 hours
        );
    }

    function getTargetsInternal(uint24 playerPower,
        uint64 staminaTimestamp,
        uint256 currentHour
    ) private pure returns (uint32[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // trait bonuses not accounted for
        // targets expire on the hour

        uint32[4] memory targets;
        for(uint32 i = 0; i < targets.length; i++) {
            // we alter seed per-index or they would be all the same
            // this is a read only function so it's fine to pack all 4 params each iteration
            // for the sake of target picking it needs to be the same as in grabTarget(i)
            // even the exact type of "i" is important here
            uint256 indexSeed = uint256(keccak256(abi.encodePacked(
                staminaTimestamp, currentHour, playerPower, i
            )));
            targets[i] = uint32(
                RandomUtil.plusMinus10PercentSeeded(playerPower, indexSeed) // power
                | (uint32(indexSeed % 4) << 24) // trait
            );
        }

        return targets;
    }

    function grabTarget(
        uint24 playerPower,
        uint64 staminaTimestamp,
        uint32 enemyIndex,
        uint256 currentHour
    ) private pure returns (uint32) {
        require(enemyIndex < 4);

        uint256 enemySeed = uint256(keccak256(abi.encodePacked(
            staminaTimestamp, currentHour, playerPower, enemyIndex
        )));
        return uint32(
            RandomUtil.plusMinus10PercentSeeded(playerPower, enemySeed) // power
            | (uint32(enemySeed % 4) << 24) // trait
        );
    }

    function mintCharacter() public onlyNonContract oncePerBlock(msg.sender) {

        uint256 skillAmount = usdToSkill(mintCharacterFee);
        (,, uint256 fromUserWallet) =
            getSkillToSubtract(
                0,
                tokenRewards[msg.sender],
                skillAmount
            );
        require(skillToken.balanceOf(msg.sender) >= fromUserWallet && promos.getBit(msg.sender, 4) == false);

        uint256 convertedAmount = usdToSkill(getMintCharacterFee());
        _payContractTokenOnly(msg.sender, convertedAmount);

        uint256 seed = randoms.getRandomSeed(msg.sender);
        characters.mint(msg.sender, seed);

        // first weapon free with a character mint, max 1 star
        if(weapons.balanceOf(msg.sender) == 0) {
            weapons.mintWeaponWithStars(msg.sender, 0, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))), 100);
        }

        _updateCharacterMintFee();
    }

    function mintWeaponN(uint32 num, uint8 chosenElement, uint256 eventId)
        external
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(getMintWeaponFee() * num * chosenElementFee));
        _mintWeaponNLogic(num, chosenElement, eventId);
    }

    function mintWeapon(uint8 chosenElement, uint256 eventId) external onlyNonContract oncePerBlock(msg.sender) {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(getMintWeaponFee() * chosenElementFee));
        _mintWeaponLogic(chosenElement, eventId);
    }

    function mintWeaponNUsingStakedSkill(uint32 num, uint8 chosenElement, uint256 eventId)
        external
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        int128 discountedMintWeaponFee =
            getMintWeaponFee()
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT)
                .mul(ABDKMath64x64.fromUInt(num))
                .mul(ABDKMath64x64.fromUInt(chosenElementFee));
        _payContractStakedOnly(msg.sender, usdToSkill(discountedMintWeaponFee));

        _mintWeaponNLogic(num, chosenElement, eventId);
    }

    function mintWeaponUsingStakedSkill(uint8 chosenElement, uint256 eventId) external onlyNonContract oncePerBlock(msg.sender) {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        int128 discountedMintWeaponFee =
            getMintWeaponFee()
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT)
                .mul(ABDKMath64x64.fromUInt(chosenElementFee));
        _payContractStakedOnly(msg.sender, usdToSkill(discountedMintWeaponFee));

        _mintWeaponLogic(chosenElement, eventId);
    }

    function _mintWeaponNLogic(uint32 num, uint8 chosenElement, uint256 eventId) internal {
        require(num > 0 && num <= 10);
        if(eventId > 0) {
            specialWeaponsManager.addShards(msg.sender, eventId, num);
        }
        _updateWeaponMintFee(num);
        weapons.mintN(msg.sender, num, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))), chosenElement);
    }

    function _mintWeaponLogic(uint8 chosenElement, uint256 eventId) internal {
        //uint256 seed = randoms.getRandomSeed(msg.sender);
        if(eventId > 0) {
            specialWeaponsManager.addShards(msg.sender, eventId, 1);
        }
        _updateWeaponMintFee(1);
        weapons.mint(msg.sender, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))), chosenElement);
    }

    function _updateWeaponMintFee(uint256 num) internal {
        mintWeaponFee = getMintWeaponFee() + ABDKMath64x64.divu(vars[VAR_WEAPON_FEE_INCREASE].mul(num), 1e18);
        vars[VAR_WEAPON_MINT_TIMESTAMP] = block.timestamp;
    }

    function _updateCharacterMintFee() internal {
        mintCharacterFee = getMintCharacterFee() + ABDKMath64x64.divu(vars[VAR_CHARACTER_FEE_INCREASE], 1e18);
        vars[VAR_CHARACTER_MINT_TIMESTAMP] = block.timestamp;
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        randoms = _newRandoms;
    }

    modifier onlyNonContract() {
        _onlyNonContract();
        _;
    }

    function _onlyNonContract() internal view {
        require(tx.origin == msg.sender, "ONC");
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    modifier oncePerBlock(address user) {
        _oncePerBlock(user);
        _;
    }

    function _oncePerBlock(address user) internal {
        require(lastBlockNumberCalled[user] < block.number, "OCB");
        lastBlockNumberCalled[user] = block.number;
    }

    modifier isWeaponOwner(uint256 weapon) {
        _isWeaponOwner(weapon);
        _;
    }

    function _isWeaponOwner(uint256 weapon) internal view {
        require(weapons.ownerOf(weapon) == msg.sender);
    }

    modifier isWeaponsOwner(uint256[] memory weaponArray) {
        _isWeaponsOwner(weaponArray);
        _;
    }

    function _isWeaponsOwner(uint256[] memory weaponArray) internal view {
        for(uint i = 0; i < weaponArray.length; i++) {
            require(weapons.ownerOf(weaponArray[i]) == msg.sender);
        }
    }

    modifier isCharacterOwner(uint256 character) {
        _isCharacterOwner(character);
        _;
    }

    function _isCharacterOwner(uint256 character) internal view {
        require(characters.ownerOf(character) == msg.sender);
    }

    function payPlayerConverted(address playerAddress, uint256 convertedAmount) public restricted {
        _payPlayerConverted(playerAddress, convertedAmount);
    }

    function payContractTokenOnly(address playerAddress, uint256 convertedAmount) public restricted {
        _payContractTokenOnly(playerAddress, convertedAmount, true);
    }

    function payContractTokenOnly(address playerAddress, uint256 convertedAmount, bool track) public restricted {
        _payContractTokenOnly(playerAddress, convertedAmount, track);
    }

    function _payContractTokenOnly(address playerAddress, uint256 convertedAmount) internal {
        _payContractTokenOnly(playerAddress, convertedAmount, true);
    }

    function _payContractTokenOnly(address playerAddress, uint256 convertedAmount, bool track) internal {
        (, uint256 fromTokenRewards, uint256 fromUserWallet) =
            getSkillToSubtract(
                0,
                tokenRewards[playerAddress],
                convertedAmount
            );

        _deductPlayerSkillStandard(playerAddress, 0, fromTokenRewards, fromUserWallet, track);
    }

    function _payContract(address playerAddress, int128 usdAmount) internal
        returns (uint256 _fromInGameOnlyFunds, uint256 _fromTokenRewards, uint256 _fromUserWallet) {

        return _payContractConverted(playerAddress, usdToSkill(usdAmount));
    }

    function _payContractConverted(address playerAddress, uint256 convertedAmount) internal
        returns (uint256 _fromInGameOnlyFunds, uint256 _fromTokenRewards, uint256 _fromUserWallet) {

        (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) =
            getSkillToSubtract(
                inGameOnlyFunds[playerAddress],
                tokenRewards[playerAddress],
                convertedAmount
            );

        require(skillToken.balanceOf(playerAddress) >= fromUserWallet,
            string(abi.encodePacked("Not enough SKILL! Need ",RandomUtil.uint2str(convertedAmount))));

        _deductPlayerSkillStandard(playerAddress, fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);

        return (fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);
    }

    function payContractConvertedSupportingStaked(address playerAddress, uint256 convertedAmount) external restricted
        returns (
            uint256 _fromInGameOnlyFunds,
            uint256 _fromTokenRewards,
            uint256 _fromUserWallet,
            uint256 _fromStaked
        ) {
        return _payContractConvertedSupportingStaked(playerAddress, convertedAmount);
    }

    function _payContractConvertedSupportingStaked(address playerAddress, uint256 convertedAmount) internal
        returns (
            uint256 _fromInGameOnlyFunds,
            uint256 _fromTokenRewards,
            uint256 _fromUserWallet,
            uint256 _fromStaked
        ) {

        (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 _remainder) =
            getSkillToSubtract(
                inGameOnlyFunds[playerAddress],
                tokenRewards[playerAddress],
                convertedAmount
            );

        (uint256 fromUserWallet, uint256 fromStaked) =
            getSkillToSubtractSingle(
                _remainder,
                skillToken.balanceOf(playerAddress)
            );

        _deductPlayerSkillStandard(playerAddress, fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);

        if(fromStaked > 0) {
            stakeFromGameImpl.unstakeToGame(playerAddress, fromStaked);
            _trackIncome(fromStaked);
        }

        return (fromInGameOnlyFunds, fromTokenRewards, fromUserWallet, fromStaked);
    }

    function _payContractStakedOnly(address playerAddress, uint256 convertedAmount) internal {
        stakeFromGameImpl.unstakeToGame(playerAddress, convertedAmount);
        _trackIncome(convertedAmount);
    }

    function payContractStakedOnly(address playerAddress, uint256 convertedAmount) external restricted {
        _payContractStakedOnly(playerAddress, convertedAmount);
    }

    function _deductPlayerSkillStandard(
        address playerAddress,
        uint256 fromInGameOnlyFunds,
        uint256 fromTokenRewards,
        uint256 fromUserWallet
    ) internal {
        _deductPlayerSkillStandard(
            playerAddress,
            fromInGameOnlyFunds,
            fromTokenRewards,
            fromUserWallet,
            true
        );
    }

    function _deductPlayerSkillStandard(
        address playerAddress,
        uint256 fromInGameOnlyFunds,
        uint256 fromTokenRewards,
        uint256 fromUserWallet,
        bool trackInflow
    ) internal {
        if(fromInGameOnlyFunds > 0) {
            totalInGameOnlyFunds = totalInGameOnlyFunds.sub(fromInGameOnlyFunds);
            inGameOnlyFunds[playerAddress] = inGameOnlyFunds[playerAddress].sub(fromInGameOnlyFunds);
        }

        if(fromTokenRewards > 0) {
            tokenRewards[playerAddress] = tokenRewards[playerAddress].sub(fromTokenRewards);
        }

        if(fromUserWallet > 0) {
            skillToken.transferFrom(playerAddress, address(this), fromUserWallet);
            if(trackInflow)
                _trackIncome(fromUserWallet);
        }
    }

    function deductAfterPartnerClaim(uint256 amount, address player) external restricted {
        tokenRewards[player] = tokenRewards[player].sub(amount);
        vars[VAR_UNCLAIMED_SKILL] -= amount;
        _trackIncome(amount);
    }

    function trackIncome(uint256 income) public restricted {
        _trackIncome(income);
    }

    function _trackIncome(uint256 income) internal {
        vars[VAR_HOURLY_INCOME] += ABDKMath64x64.divu(vars[VAR_PARAM_PAYOUT_INCOME_PERCENT],100)
                .mulu(income);
        updateHourlyPayouts();
    }

    function updateHourlyPayouts() internal {
        // Could be done by a bot instead?
        if(now - vars[VAR_HOURLY_TIMESTAMP] >= 1 hours) {
            vars[VAR_HOURLY_TIMESTAMP] = now;

            uint256 undistributed = vars[VAR_HOURLY_INCOME] + vars[VAR_HOURLY_DISTRIBUTION];

            vars[VAR_HOURLY_DISTRIBUTION] = undistributed > vars[VAR_PARAM_HOURLY_PAY_ALLOWANCE]
                ? vars[VAR_PARAM_HOURLY_PAY_ALLOWANCE] : undistributed;
            vars[VAR_HOURLY_INCOME] = undistributed.sub(vars[VAR_HOURLY_DISTRIBUTION]);

            uint256 fights = vars[VAR_HOURLY_FIGHTS];
            if(fights >= vars[VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS]) {
                uint256 averagePower = vars[VAR_HOURLY_POWER_SUM] / fights;

                if(averagePower > vars[VAR_HOURLY_MAX_POWER_AVERAGE])
                    vars[VAR_HOURLY_MAX_POWER_AVERAGE] = averagePower;
            }
            vars[VAR_HOURLY_POWER_AVERAGE] = ABDKMath64x64.divu(vars[VAR_PARAM_HOURLY_MAX_POWER_PERCENT],100)
                .mulu(vars[VAR_HOURLY_MAX_POWER_AVERAGE]);

            vars[VAR_DAILY_MAX_CLAIM] = vars[VAR_HOURLY_PAY_PER_FIGHT] * vars[VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT];
            vars[VAR_HOURLY_FIGHTS] = 0;
            vars[VAR_HOURLY_POWER_SUM] = 0;
        }
    }

    function _payPlayer(address playerAddress, int128 baseAmount) internal {
        _payPlayerConverted(playerAddress, usdToSkill(baseAmount));
    }

    function _payPlayerConverted(address playerAddress, uint256 convertedAmount) internal {
        skillToken.transfer(playerAddress, convertedAmount);
    }

    function setCharacterMintValue(uint256 cents) public restricted {
        mintCharacterFee = ABDKMath64x64.divu(cents, 100);
    }

    function setWeaponMintValue(uint256 cents) public restricted {
        mintWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setStaminaCostFight(uint8 points) public restricted {
        staminaCostFight = points;
    }

    function setDurabilityCostFight(uint8 points) public restricted {
        durabilityCostFight = points;
    }

    function setFightXpGain(uint256 average) public restricted {
        fightXpGain = average;
    }

    function setRewardsClaimTaxMaxAsPercent(uint256 _percent) public restricted {
        rewardsClaimTaxMax = ABDKMath64x64.divu(_percent, 100);
    }

    function setRewardsClaimTaxDuration(uint256 _rewardsClaimTaxDuration) public restricted {
        rewardsClaimTaxDuration = _rewardsClaimTaxDuration;
    }

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    function giveInGameOnlyFunds(address to, uint256 skillAmount) external restricted {
        totalInGameOnlyFunds = totalInGameOnlyFunds.add(skillAmount);
        inGameOnlyFunds[to] = inGameOnlyFunds[to].add(skillAmount);

        skillToken.safeTransferFrom(msg.sender, address(this), skillAmount);

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

    function claimTokenRewards() public {
        claimTokenRewards(getRemainingTokenClaimAmountPreTax());
    }

    function claimTokenRewards(uint256 _claimingAmount) public {

        trackDailyClaim(_claimingAmount);

        uint256 _tokenRewardsToPayOut = _claimingAmount.sub(
            _getRewardsClaimTax(msg.sender).mulu(_claimingAmount)
        );

        // Tax goes to game contract itself, which would mean
        // transferring from the game contract to ...itself.
        // So we don't need to do anything with the tax part of the rewards.
        if(promos.getBit(msg.sender, 4) == false) {
            _payPlayerConverted(msg.sender, _tokenRewardsToPayOut);
            if(_tokenRewardsToPayOut <= vars[VAR_UNCLAIMED_SKILL])
                vars[VAR_UNCLAIMED_SKILL] -= _tokenRewardsToPayOut;
        }
    }

    function trackDailyClaim(uint256 _claimingAmount) internal {

        if(isDailyTokenClaimAmountExpired()) {
            userVars[msg.sender][USERVAR_CLAIM_TIMESTAMP] = now;
            userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT] = 0;
        }
        require(_claimingAmount <= getRemainingTokenClaimAmountPreTax() && _claimingAmount > 0);
        // safemath throws error on negative
        tokenRewards[msg.sender] = tokenRewards[msg.sender].sub(_claimingAmount);
        userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT] += _claimingAmount;
    }

    function isDailyTokenClaimAmountExpired() public view returns (bool) {
        return userVars[msg.sender][USERVAR_CLAIM_TIMESTAMP] <= now - 1 days;
    }

    function getClaimedTokensToday() public view returns (uint256) {
        // if claim timestamp is older than a day, it's reset to 0
        return isDailyTokenClaimAmountExpired() ? 0 : userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT];
    }

    function getRemainingTokenClaimAmountPreTax() public view returns (uint256) {
        // used to get how much can be withdrawn until the daily withdraw timer expires
        uint256 max = getMaxTokenClaimAmountPreTax();
        uint256 claimed = getClaimedTokensToday();
        if(claimed >= max)
            return 0; // all tapped out for today
        uint256 remainingOfMax = max-claimed;
        return tokenRewards[msg.sender] >= remainingOfMax ? remainingOfMax : tokenRewards[msg.sender];
    }

    function getMaxTokenClaimAmountPreTax() public view returns(uint256) {
        // if tokenRewards is above VAR_CLAIM_DEPOSIT_AMOUNT, we let them withdraw more
        // this function does not account for amount already withdrawn today
        if(tokenRewards[msg.sender] >= vars[VAR_CLAIM_DEPOSIT_AMOUNT]) { // deposit bonus active
            // max is either 10% of amount above deposit, or 2x the regular limit, whichever is higher
            uint256 aboveDepositAdjusted = ABDKMath64x64.divu(vars[VAR_PARAM_DAILY_CLAIM_DEPOSIT_PERCENT],100)
                .mulu(tokenRewards[msg.sender]-vars[VAR_CLAIM_DEPOSIT_AMOUNT]); // 10% above deposit
            if(aboveDepositAdjusted > vars[VAR_DAILY_MAX_CLAIM] * 2) {
                return aboveDepositAdjusted;
            }
            return vars[VAR_DAILY_MAX_CLAIM] * 2;
        }
        return vars[VAR_DAILY_MAX_CLAIM];
    }

    function stakeUnclaimedRewards() public {
        stakeUnclaimedRewards(getRemainingTokenClaimAmountPreTax());
    }

    function stakeUnclaimedRewards(uint256 amount) public {

        trackDailyClaim(amount);

        if(promos.getBit(msg.sender, 4) == false) {
            skillToken.approve(address(stakeFromGameImpl), amount);
            stakeFromGameImpl.stakeFromGame(msg.sender, amount);
        }
    }

    function claimXpRewards() public {
        // our characters go to the tavern to rest
        // they meditate on what they've learned

        uint256[] memory chars = characters.getReadyCharacters(msg.sender);
        require(chars.length > 0);
        uint256[] memory xps = new uint256[](chars.length);
        for(uint256 i = 0; i < chars.length; i++) {
            xps[i] = xpRewards[chars[i]];
            xpRewards[chars[i]] = 0;
        }
        characters.gainXpAll(chars, xps);
    }

    function resetXp(uint256[] memory chars) public restricted {
        for(uint256 i = 0; i < chars.length; i++) {
            xpRewards[chars[i]] = 0;
        }
    }

    function getTokenRewards() public view returns (uint256) {
        return tokenRewards[msg.sender];
    }

    function getXpRewards(uint256[] memory chars) public view returns (uint256[] memory) {
        uint charsAmount = chars.length;
        uint256[] memory xps = new uint256[](charsAmount);
        for(uint i = 0; i < chars.length; i++) {
            xps[i] = xpRewards[chars[i]];
        }
        return xps;
    }

    function getTokenRewardsFor(address wallet) public view returns (uint256) {
        return tokenRewards[wallet];
    }

    function getTotalSkillOwnedBy(address wallet) public view returns (uint256) {
        return inGameOnlyFunds[wallet] + getTokenRewardsFor(wallet) + skillToken.balanceOf(wallet);
    }

    function _getRewardsClaimTax(address playerAddress) internal view returns (int128) {
        assert(_rewardsClaimTaxTimerStart[playerAddress] <= block.timestamp);

        uint256 rewardsClaimTaxTimerEnd = _rewardsClaimTaxTimerStart[playerAddress].add(rewardsClaimTaxDuration);

        (, uint256 durationUntilNoTax) = rewardsClaimTaxTimerEnd.trySub(block.timestamp);

        assert(0 <= durationUntilNoTax && durationUntilNoTax <= rewardsClaimTaxDuration);

        int128 frac = ABDKMath64x64.divu(durationUntilNoTax, rewardsClaimTaxDuration);

        return rewardsClaimTaxMax.mul(frac);
    }

    function getOwnRewardsClaimTax() public view returns (int128) {
        return _getRewardsClaimTax(msg.sender);
    }

    function getMintWeaponFee() public view returns (int128) {
        int128 decrease = ABDKMath64x64.divu(block.timestamp.sub(vars[VAR_WEAPON_MINT_TIMESTAMP]).mul(vars[VAR_MINT_WEAPON_FEE_DECREASE_SPEED]), 1e18);
        int128 weaponFeeMin = ABDKMath64x64.divu(vars[VAR_MIN_WEAPON_FEE], 100);
        if(decrease > mintWeaponFee) {
            return weaponFeeMin;
        }
        if(mintWeaponFee - decrease < weaponFeeMin) {
            return weaponFeeMin;
        }
        return mintWeaponFee.sub(decrease);
    }

    function getMintCharacterFee() public view returns (int128) {
        int128 decrease = ABDKMath64x64.divu(block.timestamp.sub(vars[VAR_CHARACTER_MINT_TIMESTAMP]).mul(vars[VAR_MINT_CHARACTER_FEE_DECREASE_SPEED]), 1e18);
        int128 characterFeeMin = ABDKMath64x64.divu(vars[VAR_MIN_CHARACTER_FEE], 100);
        if(decrease > mintCharacterFee) {
            return characterFeeMin;
        }
        if(mintCharacterFee - decrease < characterFeeMin) {
            return characterFeeMin;
        }
        return mintCharacterFee.sub(decrease);
    }

}
