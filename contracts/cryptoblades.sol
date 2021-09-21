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
import "./Blacksmith.sol";

contract CryptoBlades is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeERC20 for IERC20;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    int128 public constant PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT =
        14757395258967641292; // 0.8 in fixed-point 64x64 format

    // Payment must be recent enough that the hash is available for the payment block.
    // Use 200 as a 'friendly' window of "You have 10 minutes."
    uint256 public constant MINT_PAYMENT_TIMEOUT = 200;
    uint256 public constant MINT_PAYMENT_RECLAIM_MINIMUM_WAIT_TIME = 3 hours;

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

    event FightOutcome(address indexed owner, uint256 indexed character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll, uint16 xpGain, uint256 skillGain);
    event InGameOnlyFundsGiven(address indexed to, uint256 skillAmount);
    event MintWeaponsSuccess(address indexed minter, uint32 count);
    event MintWeaponsFailure(address indexed minter, uint32 count);

    function recoverSkill(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

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

    function fight(uint256 char, uint256 wep, uint32 target, uint8 fightMultiplier) external
            // These have been combined due to error: CompilerError: Stack too deep, try removing local variables. TODO
            // onlyNonContract
            // isCharacterOwner(char)
            // isWeaponOwner(wep) {
        fightModifierChecks(char, wep) {
        require(fightMultiplier >= 1 && fightMultiplier <= 5);

        (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) =
            unpackFightData(characters.getFightDataAndDrainStamina(char, staminaCostFight * fightMultiplier, false));

        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightDataAndDrainDurability(wep, charTrait,
                durabilityCostFight * fightMultiplier, false);

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
            uint24(target & 0xFFFFFF),
            fightMultiplier
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
            now.div(1 hours),
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

    function isUnlikely(uint24 pp, uint24 ep)
        private
        pure
        returns(bool)
    {
        int128 playerMin = ABDKMath64x64.fromUInt(pp).mul(ABDKMath64x64.fromUInt(90)).div(ABDKMath64x64.fromUInt(100));
        int128 playerMax = ABDKMath64x64.fromUInt(pp).mul(ABDKMath64x64.fromUInt(110)).div(ABDKMath64x64.fromUInt(100));
        int128 playerRange = playerMax.sub(playerMin);
        int128 enemyMin = ABDKMath64x64.fromUInt(ep).mul(ABDKMath64x64.fromUInt(90)).div(ABDKMath64x64.fromUInt(100));
        int128 enemyMax = ABDKMath64x64.fromUInt(ep).mul(ABDKMath64x64.fromUInt(110)).div(ABDKMath64x64.fromUInt(100));
        int128 enemyRange = enemyMax.sub(enemyMin);
        int256 rollingTotal = 0;

        if (playerMin > enemyMax) return false;
        if (playerMax < enemyMin) return true;

        if (playerMin >= enemyMin) {
            int128 temp = playerMin.sub(enemyMin).div(enemyRange);
            temp = temp.add(ABDKMath64x64.fromUInt(1).sub(temp).mul(playerMax.sub(enemyMax).div(playerRange)));
            temp = temp.add(ABDKMath64x64.fromUInt(1).sub(temp).mul(ABDKMath64x64.fromUInt(50).div(ABDKMath64x64.fromUInt(100))));
            rollingTotal = ABDKMath64x64.toInt(temp.mul(ABDKMath64x64.fromUInt(1000)));
        } else {
            int128 temp = enemyMin.sub(playerMin).div(playerRange);
            temp = temp.add(ABDKMath64x64.fromUInt(1).sub(temp).mul(enemyMax.sub(playerMax).div(enemyRange)));
            temp = temp.add(ABDKMath64x64.fromUInt(1).sub(temp).mul(ABDKMath64x64.fromUInt(50).div(ABDKMath64x64.fromUInt(100))));
            temp = ABDKMath64x64.fromUInt(1).sub(temp);
            rollingTotal = ABDKMath64x64.toInt(temp.mul(ABDKMath64x64.fromUInt(1000)));
        }

        return rollingTotal <= 300 ? true : false;
    }

    function performFight(
        uint256 char,
        uint256 wep,
        uint24 playerFightPower,
        uint24 traitsCWE, // could fit into uint8 since each trait is only stored on 2 bits (TODO)
        uint24 targetPower,
        uint8 fightMultiplier
    ) private {
        uint256 seed = randoms.getRandomSeed(msg.sender);
        uint24 playerRoll = getPlayerPowerRoll(playerFightPower,traitsCWE,seed);
        uint24 monsterRoll = getMonsterPowerRoll(targetPower, RandomUtil.combineSeeds(seed,1));

        uint16 xp = getXpGainForFight(playerFightPower, targetPower) * fightMultiplier;
        uint256 tokens = usdToSkill(getTokenGainForFight(targetPower, fightMultiplier));

        if(playerRoll < monsterRoll) {
            tokens = 0;
            xp = 0;
        }

        if(tokenRewards[msg.sender] == 0 && tokens > 0) {
            _rewardsClaimTaxTimerStart[msg.sender] = block.timestamp;
        }

        // this may seem dumb but we want to avoid guessing the outcome based on gas estimates!
        tokenRewards[msg.sender] += tokens;
        xpRewards[char] += xp;

        // if (playerRoll > monsterRoll && isUnlikely(uint24(getPlayerTraitBonusAgainst(traitsCWE).mulu(playerFightPower)), targetPower)) {
        //     blacksmith.giveTicket(msg.sender, 1);
        // }

        emit FightOutcome(msg.sender, char, wep, (targetPower | ((uint32(traitsCWE) << 8) & 0xFF000000)), playerRoll, monsterRoll, xp, tokens);
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight(uint24 monsterPower, uint8 fightMultiplier) internal view returns (int128) {
        return fightRewardGasOffset.add(
            fightRewardBaseline.mul(
                ABDKMath64x64.sqrt(
                    // Performance optimization: 1000 = getPowerAtLevel(0)
                    ABDKMath64x64.divu(monsterPower, 1000)
                )
            ).mul(ABDKMath64x64.fromUInt(fightMultiplier))
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
            now.div(1 hours)
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

    /*function mintPaymentSkillRefundable(address _minter) external view
        returns (uint256 _refundInGameOnlyFunds, uint256 _refundTokenRewards, uint256 _refundUserWallet) {

        return (
            mintPaymentSkillDepositeds[_minter].skillRefundableFromIgo,
            mintPaymentSkillDepositeds[_minter].skillRefundableFromRewards,
            mintPaymentSkillDepositeds[_minter].skillRefundableFromWallet
        );
    }

    function mintPaymentSecondsUntilSkillRefundClaimable(address _minter) external view
        returns (uint256) {

        (bool success, uint256 result) =
            mintPaymentSkillDepositeds[_minter].refundClaimableTimestamp.trySub(block.timestamp);

        if(success) {
            return result;
        }
        else {
            return 0;
        }
    }

    function checkIfMintPaymentExpiredAndRefunded() external {
        _discardPaymentIfExpired(msg.sender);
    }

    function mintPaymentClaimRefund() external {
        _discardPaymentIfExpired(msg.sender);

        require(mintPaymentSkillDepositeds[msg.sender].refundClaimableTimestamp <= block.timestamp);

        uint256 skillRefundableFromIgo = mintPaymentSkillDepositeds[msg.sender].skillRefundableFromIgo;
        uint256 skillRefundableFromRewards = mintPaymentSkillDepositeds[msg.sender].skillRefundableFromRewards;
        uint256 skillRefundableFromWallet = mintPaymentSkillDepositeds[msg.sender].skillRefundableFromWallet;

        require(skillRefundableFromWallet > 0 || skillRefundableFromRewards > 0 || skillRefundableFromIgo > 0);

        mintPaymentSkillDepositeds[msg.sender].skillRefundableFromIgo = 0;
        mintPaymentSkillDepositeds[msg.sender].skillRefundableFromRewards = 0;
        mintPaymentSkillDepositeds[msg.sender].skillRefundableFromWallet = 0;

        totalMintPaymentSkillRefundable = totalMintPaymentSkillRefundable
                .sub(skillRefundableFromWallet)
                .sub(skillRefundableFromRewards)
                .sub(skillRefundableFromIgo);

        totalInGameOnlyFunds = totalInGameOnlyFunds.add(skillRefundableFromIgo);
        inGameOnlyFunds[msg.sender] = inGameOnlyFunds[msg.sender].add(skillRefundableFromIgo);

        tokenRewards[msg.sender] = tokenRewards[msg.sender].add(skillRefundableFromRewards);
        skillToken.transfer(msg.sender, skillRefundableFromWallet);
    }

    function _updatePaymentBlockHash(address _minter) internal {
        if ((mintPayments[_minter].count > 0) &&
            (mintPayments[_minter].blockHash == 0) &&
            (mintPayments[_minter].blockNumber < block.number) &&
            (mintPayments[_minter].blockNumber + MINT_PAYMENT_TIMEOUT >= block.number)) {

            mintPayments[_minter].blockHash = blockhash(mintPayments[_minter].blockNumber);
        }
    }

    function _discardPaymentIfExpired(address _minter) internal {
        _updatePaymentBlockHash(_minter);
        if ((mintPayments[_minter].count > 0) &&
            (mintPayments[_minter].blockHash == 0)) {

            uint256 depositedSkillFromWallet = mintPaymentSkillDepositeds[_minter].skillDepositedFromWallet;
            uint256 depositedSkillFromRewards = mintPaymentSkillDepositeds[_minter].skillDepositedFromRewards;
            uint256 depositedSkillFromIgo = mintPaymentSkillDepositeds[_minter].skillDepositedFromIgo;
            mintPaymentSkillDepositeds[_minter].skillDepositedFromWallet = 0;
            mintPaymentSkillDepositeds[_minter].skillDepositedFromRewards = 0;
            mintPaymentSkillDepositeds[_minter].skillDepositedFromIgo = 0;

            mintPaymentSkillDepositeds[_minter].skillRefundableFromWallet =
                mintPaymentSkillDepositeds[_minter].skillRefundableFromWallet.add(depositedSkillFromWallet);
            mintPaymentSkillDepositeds[_minter].skillRefundableFromRewards =
                mintPaymentSkillDepositeds[_minter].skillRefundableFromRewards.add(depositedSkillFromRewards);
            mintPaymentSkillDepositeds[_minter].skillRefundableFromIgo =
                mintPaymentSkillDepositeds[_minter].skillRefundableFromIgo.add(depositedSkillFromIgo);

            totalMintPaymentSkillRefundable = totalMintPaymentSkillRefundable
                .add(depositedSkillFromWallet)
                .add(depositedSkillFromRewards)
                .add(depositedSkillFromIgo);
            mintPaymentSkillDepositeds[_minter].refundClaimableTimestamp = block.timestamp + 3 hours;

            delete mintPayments[_minter];
        }
    }

    function hasPaidForMint(uint32 _num) public view returns(bool){
        require(_num > 0);
        return (
            mintPayments[msg.sender].count == _num && (
                mintPayments[msg.sender].blockHash != 0 ||
                mintPayments[msg.sender].blockNumber + MINT_PAYMENT_TIMEOUT >= block.number
            )
        );
    }

    function payForMint(address nftAddress, uint count) public {
        _discardPaymentIfExpired(msg.sender);

        require(
            mintPaymentSkillDepositeds[msg.sender].skillRefundableFromWallet == 0 &&
            mintPaymentSkillDepositeds[msg.sender].skillRefundableFromRewards == 0 &&
            mintPaymentSkillDepositeds[msg.sender].skillRefundableFromIgo == 0
        );

        require(mintPayments[msg.sender].count == 0);

        require(nftAddress == address(weapons));
        (uint256 _paidFeeFromInGameOnlyFunds, uint256 _paidFeeFromTokenRewards, uint256 _paidFeeFromUserWallet) =
            _payContract(msg.sender, mintWeaponFee * int128(count));

        require(count == 1 || count == 10);

        mintPayments[msg.sender].count = count;
        mintPayments[msg.sender].nftAddress = nftAddress;
        mintPayments[msg.sender].blockNumber = block.number;
        mintPayments[msg.sender].blockHash = 0;
        mintPaymentSkillDepositeds[msg.sender].skillDepositedFromWallet =
            mintPaymentSkillDepositeds[msg.sender].skillDepositedFromWallet.add(_paidFeeFromUserWallet);
        mintPaymentSkillDepositeds[msg.sender].skillDepositedFromRewards =
            mintPaymentSkillDepositeds[msg.sender].skillDepositedFromRewards.add(_paidFeeFromTokenRewards);
        mintPaymentSkillDepositeds[msg.sender].skillDepositedFromIgo =
            mintPaymentSkillDepositeds[msg.sender].skillDepositedFromIgo.add(_paidFeeFromInGameOnlyFunds);
    }

    function _usePayment(address _minter, address nftAddress, uint count) internal {
        _discardPaymentIfExpired(_minter);

        require(mintPayments[_minter].nftAddress == nftAddress);
        // Payment must commit in a block before being used.
        require(mintPayments[_minter].blockNumber < block.number);

        mintPayments[_minter].count = mintPayments[_minter].count.sub(count);
        mintPayments[_minter].blockHash = bytes32(uint256(mintPayments[_minter].blockHash) + 1);
        if (mintPayments[_minter].count == 0) {
            delete mintPayments[_minter];
        }
    }*/

    function mintCharacter() public onlyNonContract oncePerBlock(msg.sender) {

        uint256 skillAmount = usdToSkill(mintCharacterFee);
        (,, uint256 fromUserWallet) =
            getSkillToSubtract(
                0,
                tokenRewards[msg.sender],
                skillAmount
            );
        require(skillToken.balanceOf(msg.sender) >= fromUserWallet && promos.getBit(msg.sender, 4) == false);

        uint256 convertedAmount = usdToSkill(mintCharacterFee);
        _payContractTokenOnly(msg.sender, convertedAmount);

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

    /*function mintWeaponN(uint32 num)
        public
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        require(num > 0 && num <= 1000);
        _discardPaymentIfExpired(msg.sender);
        require(mintPayments[msg.sender].count == num, "count mismatch");

        // the function below is external so we can try-catch on it
        try this._mintWeaponNUsableByThisOnlyButExternalForReasons(msg.sender, num) {
            emit MintWeaponsSuccess(msg.sender, num);
        }
        catch {
            emit MintWeaponsFailure(msg.sender, num);
        }
    }

    function _mintWeaponNUsableByThisOnlyButExternalForReasons(address _minter, uint32 num) external {
        // the reason referred to in the function name is that we want to
        // try-catch on this from within the same contract

        require(msg.sender == address(this));

        for (uint i = 0; i < num; i++) {
            bytes32 hash = mintPayments[_minter].blockHash;
            weapons.mint(_minter, randoms.getRandomSeedUsingHash(_minter, hash));
            _usePayment(_minter, address(weapons), 1);
        }

        mintPaymentSkillDepositeds[_minter].skillDepositedFromWallet = 0;
        mintPaymentSkillDepositeds[_minter].skillDepositedFromRewards = 0;
        mintPaymentSkillDepositeds[_minter].skillDepositedFromIgo = 0;
    }

    function mintWeapon() public onlyNonContract oncePerBlock(msg.sender)  {
        _discardPaymentIfExpired(msg.sender);

        require(mintPayments[msg.sender].count == 1, "count mismatch");

        bytes32 hash = mintPayments[msg.sender].blockHash;
        try weapons.mint(msg.sender, randoms.getRandomSeedUsingHash(msg.sender, hash)) {
            _usePayment(msg.sender, address(weapons), 1);

            mintPaymentSkillDepositeds[msg.sender].skillDepositedFromWallet = 0;
            mintPaymentSkillDepositeds[msg.sender].skillDepositedFromRewards = 0;
            mintPaymentSkillDepositeds[msg.sender].skillDepositedFromIgo = 0;

            emit MintWeaponsSuccess(msg.sender, 1);
        }
        catch {
            emit MintWeaponsFailure(msg.sender, 1);
        }
    }*/

    function mintWeaponN(uint32 num)
        external
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(mintWeaponFee * num));
        _mintWeaponNLogic(num);
    }

    function mintWeapon() external onlyNonContract oncePerBlock(msg.sender) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(mintWeaponFee));
        _mintWeaponLogic();
    }

    function mintWeaponNUsingStakedSkill(uint32 num)
        external
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        int128 discountedMintWeaponFee =
            mintWeaponFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT)
                .mul(ABDKMath64x64.fromUInt(num));
        _payContractStakedOnly(msg.sender, usdToSkill(discountedMintWeaponFee));

        _mintWeaponNLogic(num);
    }

    function mintWeaponUsingStakedSkill() external onlyNonContract oncePerBlock(msg.sender) {
        int128 discountedMintWeaponFee =
            mintWeaponFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedMintWeaponFee));

        _mintWeaponLogic();
    }

    function _mintWeaponNLogic(uint32 num) internal {
        require(num > 0 && num <= 10);

        for (uint i = 0; i < num; i++) {
            weapons.mint(msg.sender, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, i))));
        }
    }

    function mintWeaponNforAddress(address _minter, uint32 num)
        public
        onlyNonContract
        oncePerBlock(_minter)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(GAME_ADMIN, msg.sender), "Not admin");
        require(num > 0 && num <= 50);

        for (uint i = 0; i < num; i++) {
            weapons.mint(_minter, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _minter, i))));
        }
    }

    function _mintWeaponLogic() internal {
        //uint256 seed = randoms.getRandomSeed(msg.sender);
        weapons.mint(msg.sender, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))));
    }

    function burnWeapon(uint256 burnID) external isWeaponOwner(burnID) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(burnWeaponFee));

        _burnWeaponLogic(burnID);
    }

    function burnWeapons(uint256[] calldata burnIDs) external isWeaponsOwner(burnIDs) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(burnWeaponFee.mul(ABDKMath64x64.fromUInt(burnIDs.length))));

        _burnWeaponsLogic(burnIDs);
    }

    function reforgeWeapon(uint256 reforgeID, uint256 burnID) external isWeaponOwner(reforgeID) isWeaponOwner(burnID) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(reforgeWeaponFee));

        _reforgeWeaponLogic(reforgeID, burnID);
    }

    function reforgeWeaponWithDust(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) external isWeaponOwner(reforgeID) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(reforgeWeaponWithDustFee));

        _reforgeWeaponWithDustLogic(reforgeID, amountLB, amount4B, amount5B);
    }

    function burnWeaponUsingStakedSkill(uint256 burnID) external isWeaponOwner(burnID) {
        int128 discountedBurnWeaponFee =
            burnWeaponFee.mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedBurnWeaponFee));

        _burnWeaponLogic(burnID);
    }

    function burnWeaponsUsingStakedSkill(uint256[] calldata burnIDs) external isWeaponsOwner(burnIDs) {
        int128 discountedBurnWeaponFee =
            burnWeaponFee
                .mul(ABDKMath64x64.fromUInt(burnIDs.length))
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedBurnWeaponFee));

        _burnWeaponsLogic(burnIDs);
    }

    function reforgeWeaponUsingStakedSkill(uint256 reforgeID, uint256 burnID) external isWeaponOwner(reforgeID) isWeaponOwner(burnID) {
        int128 discountedReforgeWeaponFee =
            reforgeWeaponFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedReforgeWeaponFee));

        _reforgeWeaponLogic(reforgeID, burnID);
    }

    function reforgeWeaponWithDustUsingStakedSkill(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) external isWeaponOwner(reforgeID) {
        int128 discountedReforgeWeaponWithDustFee =
            reforgeWeaponWithDustFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedReforgeWeaponWithDustFee));

        _reforgeWeaponWithDustLogic(reforgeID, amountLB, amount4B, amount5B);
    }

    function _burnWeaponLogic(uint256 burnID) internal {
        weapons.burn(burnID);
    }

    function _burnWeaponsLogic(uint256[] memory burnIDs) internal {
        for(uint i = 0; i < burnIDs.length; i++) {
            weapons.burn(burnIDs[i]);
        }
    }

    function _reforgeWeaponLogic(uint256 reforgeID, uint256 burnID) internal {
        weapons.reforge(reforgeID, burnID);
    }

    function _reforgeWeaponWithDustLogic(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) internal {
        weapons.reforgeWithDust(reforgeID, amountLB, amount4B, amount5B);
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        randoms = _newRandoms;
    }

    modifier fightModifierChecks(uint256 character, uint256 weapon) {
        _onlyNonContract();
        _isCharacterOwner(character);
        _isWeaponOwner(weapon);
        _;
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
        require(weapons.ownerOf(weapon) == msg.sender, "Not the weapon owner");
    }

    modifier isWeaponsOwner(uint256[] memory weaponArray) {
        _isWeaponsOwner(weaponArray);
        _;
    }

    function _isWeaponsOwner(uint256[] memory weaponArray) internal view {
        for(uint i = 0; i < weaponArray.length; i++) {
            require(weapons.ownerOf(weaponArray[i]) == msg.sender, "Not the weapon owner");
        }
    }

    modifier isCharacterOwner(uint256 character) {
        _isCharacterOwner(character);
        _;
    }

    function _isCharacterOwner(uint256 character) internal view {
        require(characters.ownerOf(character) == msg.sender, "Not the character owner");
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
        _requestPayFromPlayer(usdAmount);
        _;
    }

    function _requestPayFromPlayer(int128 usdAmount) internal view {
        uint256 skillAmount = usdToSkill(usdAmount);

        (,, uint256 fromUserWallet) =
            getSkillToSubtract(
                inGameOnlyFunds[msg.sender],
                tokenRewards[msg.sender],
                skillAmount
            );

        require(skillToken.balanceOf(msg.sender) >= fromUserWallet);
    }

    function payPlayerConverted(address playerAddress, uint256 convertedAmount) public restricted {
        _payPlayerConverted(playerAddress, convertedAmount);
    }

    function approveContractWeaponFor(uint256 weaponID, address playerAddress) public restricted {
        _approveContractWeaponFor(weaponID, playerAddress);
    }

    function payContractTokenOnly(address playerAddress, uint256 convertedAmount) public restricted {
        _payContractTokenOnly(playerAddress, convertedAmount);
    }

    function _payContractTokenOnly(address playerAddress, uint256 convertedAmount) internal {
        (, uint256 fromTokenRewards, uint256 fromUserWallet) =
            getSkillToSubtract(
                0,
                tokenRewards[playerAddress],
                convertedAmount
            );

        tokenRewards[playerAddress] = tokenRewards[playerAddress].sub(fromTokenRewards);
        skillToken.transferFrom(playerAddress, address(this), fromUserWallet);
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

        _deductPlayerSkillStandard(playerAddress, fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);

        return (fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);
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
        }

        return (fromInGameOnlyFunds, fromTokenRewards, fromUserWallet, fromStaked);
    }

    function _payContractStakedOnly(address playerAddress, uint256 convertedAmount) internal {
        stakeFromGameImpl.unstakeToGame(playerAddress, convertedAmount);
    }

    function _deductPlayerSkillStandard(
        address playerAddress,
        uint256 fromInGameOnlyFunds,
        uint256 fromTokenRewards,
        uint256 fromUserWallet
    ) internal {
        totalInGameOnlyFunds = totalInGameOnlyFunds.sub(fromInGameOnlyFunds);
        inGameOnlyFunds[playerAddress] = inGameOnlyFunds[playerAddress].sub(fromInGameOnlyFunds);

        tokenRewards[playerAddress] = tokenRewards[playerAddress].sub(fromTokenRewards);
        skillToken.transferFrom(playerAddress, address(this), fromUserWallet);
    }

    function _payPlayer(address playerAddress, int128 baseAmount) internal {
        _payPlayerConverted(playerAddress, usdToSkill(baseAmount));
    }

    function _payPlayerConverted(address playerAddress, uint256 convertedAmount) internal {
        skillToken.safeTransfer(playerAddress, convertedAmount);
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

    function setBurnWeaponValue(uint256 cents) public restricted {
        burnWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setReforgeWeaponValue(uint256 cents) public restricted {
        int128 newReforgeWeaponFee = ABDKMath64x64.divu(cents, 100);
        require(newReforgeWeaponFee > burnWeaponFee, "Reforge fee must include burn fee");
        reforgeWeaponWithDustFee = newReforgeWeaponFee - burnWeaponFee;
        reforgeWeaponFee = newReforgeWeaponFee;
    }

    function setReforgeWeaponWithDustValue(uint256 cents) public restricted {
        reforgeWeaponWithDustFee = ABDKMath64x64.divu(cents, 100);
        reforgeWeaponFee = burnWeaponFee + reforgeWeaponWithDustFee;
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

    function setCharacterLimit(uint256 max) public restricted {
        characters.setCharacterLimit(max);
    }

    function setRewardsClaimTaxMax(int128 _rewardsClaimTaxMax) public restricted {
        rewardsClaimTaxMax = _rewardsClaimTaxMax;
    }

    function setRewardsClaimTaxMaxAsRational(uint256 _numerator, uint256 _denominator) public restricted {
        rewardsClaimTaxMax = ABDKMath64x64.divu(_numerator, _denominator);
    }

    function setRewardsClaimTaxMaxAsPercent(uint256 _percent) public restricted {
        rewardsClaimTaxMax = ABDKMath64x64.divu(_percent, 100);
    }

    function setRewardsClaimTaxDuration(uint256 _rewardsClaimTaxDuration) public restricted {
        rewardsClaimTaxDuration = _rewardsClaimTaxDuration;
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
        if(promos.getBit(msg.sender, 4) == false)
            _payPlayerConverted(msg.sender, _tokenRewardsToPayOut);
    }

    function stakeUnclaimedRewards() external {
        uint256 _tokenRewards = tokenRewards[msg.sender];
        tokenRewards[msg.sender] = 0;

        if(promos.getBit(msg.sender, 4) == false) {
            skillToken.approve(address(stakeFromGameImpl), _tokenRewards);
            stakeFromGameImpl.stakeFromGame(msg.sender, _tokenRewards);
        }
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

        uint256 rewardsClaimTaxTimerEnd = _rewardsClaimTaxTimerStart[playerAddress].add(rewardsClaimTaxDuration);

        (, uint256 durationUntilNoTax) = rewardsClaimTaxTimerEnd.trySub(block.timestamp);

        assert(0 <= durationUntilNoTax && durationUntilNoTax <= rewardsClaimTaxDuration);

        int128 frac = ABDKMath64x64.divu(durationUntilNoTax, rewardsClaimTaxDuration);

        return rewardsClaimTaxMax.mul(frac);
    }

    function getOwnRewardsClaimTax() public view returns (int128) {
        return _getRewardsClaimTax(msg.sender);
    }

}
