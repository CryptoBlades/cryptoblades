pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./Promos.sol";
import "./util.sol";
import "./Garrison.sol";
import "./cryptoblades.sol";

contract BurningManager is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // STATE
    Characters public characters;
    CryptoBlades public game;
    Garrison public garrison;

    mapping(address => mapping(uint256 => uint256)) public userVars;
    uint256 public constant USERVAR_SOUL_SUPPLY = 1;
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_ROI_DAYS = 1;
    uint256 public constant VAR_BURN_POWER_MULTIPLIER = 2;

    int128 public burnWeaponFee;
    int128 public reforgeWeaponWithDustFee;
    int128 public reforgeWeaponFee;
    int128 public constant PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT = 14757395258967641292; // 0.8 in fixed-point 64x64 format


    Weapons public weapons;
    IPriceOracle public priceOracleSkillPerUsd;

    function initialize(Characters _characters, Garrison _garrison, CryptoBlades _game)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        characters = _characters;
        garrison = _garrison;
        game = _game;
    }

    function migrateTo_e1fe97c(Weapons _weapons, IPriceOracle _priceOracleSkillPerUsd) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        weapons = _weapons;
        priceOracleSkillPerUsd = _priceOracleSkillPerUsd;
        burnWeaponFee = ABDKMath64x64.divu(2, 10); // 0.2 USD
        reforgeWeaponWithDustFee = ABDKMath64x64.divu(3, 10); // 0.3 USD
        reforgeWeaponFee = burnWeaponFee + reforgeWeaponWithDustFee; // 0.5 USD
    }

    // MODIFIERS

    modifier isCharactersOwner(uint256[] memory burnIds) {
        _isCharactersOwner(burnIds);
        _;
    }

    function _isCharactersOwner(uint256[] memory burnIds) internal view {
        for(uint i = 0; i < burnIds.length; i++) {
            require(characters.ownerOf(burnIds[i]) == msg.sender || garrison.characterOwner(burnIds[i]) == msg.sender, 'Not owner');
        }
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

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    modifier burningEnabled() {
        _burningEnabled();
        _;
    }

    function _burningEnabled() internal view {
        require(vars[VAR_BURN_POWER_MULTIPLIER] > 0, "Burning disabled");
    }

    // VIEWS

    function burnCharactersFee(uint256[] memory burnIds) public view returns (uint256) {
        uint256 burnFee = 0;
        for(uint i = 0; i < burnIds.length; i++) {
            burnFee += burnCharacterFee(burnIds[i]);
        }
        return burnFee;
    }

    function burnCharacterFee(uint256 burnId) public view returns (uint256) {
        return (game.vars(game.VAR_HOURLY_PAY_PER_FIGHT()) / game.vars(game.VAR_HOURLY_MAX_POWER_AVERAGE())) * 7 * characters.getTotalPower(burnId) * vars[VAR_ROI_DAYS];
    }

    function usdToSkill(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleSkillPerUsd.currentPrice());
    }

    //FUNCTIONS

    // Characters burning
    function burnCharacterFromMarket(uint256 burnId) external burningEnabled {
        require(hasRole(BURNER_ROLE, msg.sender), 'Not burner');
        game.payContractTokenOnly(tx.origin, burnCharacterFee(burnId));
        uint256[] memory burnIds = new uint256[](1);
        burnIds[0] = burnId;
        userVars[tx.origin][USERVAR_SOUL_SUPPLY] += characters.getSoulForBurns(burnIds).mul(vars[VAR_BURN_POWER_MULTIPLIER]).div(1e18);
        characters.burnIntoSoul(burnIds);
    }

    function burnCharactersIntoCharacter(uint256[] memory burnIds, uint256 targetId) public isCharactersOwner(burnIds) burningEnabled {
        game.payContractTokenOnly(msg.sender, burnCharactersFee(burnIds));
        characters.burnIntoCharacter(burnIds, targetId, vars[VAR_BURN_POWER_MULTIPLIER]);
    }

    function burnCharactersIntoSoul(uint256[] memory burnIds) public isCharactersOwner(burnIds) burningEnabled {
        game.payContractTokenOnly(msg.sender, burnCharactersFee(burnIds));
        userVars[msg.sender][USERVAR_SOUL_SUPPLY] += characters.getSoulForBurns(burnIds).mul(vars[VAR_BURN_POWER_MULTIPLIER]).div(1e18);
        characters.burnIntoSoul(burnIds);
    }

    function transferSoul(address targetAddress, uint256 soulAmount) public {
        require(msg.sender != targetAddress);
        userVars[msg.sender][USERVAR_SOUL_SUPPLY] = userVars[msg.sender][USERVAR_SOUL_SUPPLY].sub(soulAmount);
        userVars[targetAddress][USERVAR_SOUL_SUPPLY] = userVars[targetAddress][USERVAR_SOUL_SUPPLY].add(soulAmount);
    }

    function upgradeCharacterWithSoul(uint256 targetId, uint256 soulAmount) public burningEnabled {
        userVars[msg.sender][USERVAR_SOUL_SUPPLY] = userVars[msg.sender][USERVAR_SOUL_SUPPLY].sub(soulAmount);
        characters.upgradeWithSoul(targetId, soulAmount);
    }

    // Weapons burning

    function burnWeapons(uint256[] calldata burnIDs) external isWeaponsOwner(burnIDs) {
        game.payContractConvertedSupportingStaked(msg.sender, game.usdToSkill(burnWeaponFee.mul(ABDKMath64x64.fromUInt(burnIDs.length))));

        _burnWeaponsLogic(burnIDs);
    }

    function reforgeWeapon(uint256 reforgeID, uint256 burnID) external isWeaponOwner(reforgeID) isWeaponOwner(burnID) {
        game.payContractConvertedSupportingStaked(msg.sender, usdToSkill(burnWeaponFee));

        _reforgeWeaponLogic(reforgeID, burnID);
    }

    function reforgeWeaponWithDust(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) external isWeaponOwner(reforgeID) {
        game.payContractConvertedSupportingStaked(msg.sender, usdToSkill(reforgeWeaponWithDustFee));

        _reforgeWeaponWithDustLogic(reforgeID, amountLB, amount4B, amount5B);
    }

    function burnWeaponsUsingStakedSkill(uint256[] calldata burnIDs) external isWeaponsOwner(burnIDs) {
        int128 discountedBurnWeaponFee =
            burnWeaponFee
                .mul(ABDKMath64x64.fromUInt(burnIDs.length))
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        game.payContractStakedOnly(msg.sender, usdToSkill(discountedBurnWeaponFee));

        _burnWeaponsLogic(burnIDs);
    }

    function reforgeWeaponUsingStakedSkill(uint256 reforgeID, uint256 burnID) external isWeaponOwner(reforgeID) isWeaponOwner(burnID) {
        int128 discountedReforgeWeaponFee =
            reforgeWeaponFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        game.payContractStakedOnly(msg.sender, usdToSkill(discountedReforgeWeaponFee));

        _reforgeWeaponLogic(reforgeID, burnID);
    }

    function reforgeWeaponWithDustUsingStakedSkill(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) external isWeaponOwner(reforgeID) {
        int128 discountedReforgeWeaponWithDustFee =
            reforgeWeaponWithDustFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        game.payContractStakedOnly(msg.sender, usdToSkill(discountedReforgeWeaponWithDustFee));

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

    function giveAwaySoul(address user, uint256 soulAmount) external restricted {
        userVars[user][USERVAR_SOUL_SUPPLY] += soulAmount;
    }

    function burnSoul(address user, uint256 soulAmount) external restricted {
        userVars[user][USERVAR_SOUL_SUPPLY] = userVars[user][USERVAR_SOUL_SUPPLY].sub(soulAmount);
    }

    // VARS SETTER

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setBurnWeaponValue(uint256 cents) public restricted {
        burnWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setReforgeWeaponValue(uint256 cents) public restricted {
        int128 newReforgeWeaponFee = ABDKMath64x64.divu(cents, 100);
        require(newReforgeWeaponFee > burnWeaponFee);
        reforgeWeaponWithDustFee = newReforgeWeaponFee - burnWeaponFee;
        reforgeWeaponFee = newReforgeWeaponFee;
    }

    function setReforgeWeaponWithDustValue(uint256 cents) public restricted {
        reforgeWeaponWithDustFee = ABDKMath64x64.divu(cents, 100);
        reforgeWeaponFee = burnWeaponFee + reforgeWeaponWithDustFee;
    }
    
}
