pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./util.sol";
import "./Garrison.sol";
import "./cryptoblades.sol";

contract BurningManager is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;

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
    uint256 public constant VAR_BURNING_ENABLED = 3;

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
        require(vars[VAR_BURNING_ENABLED] == 1, "Burning disabled");
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

    //FUNCTIONS

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

    function upgradeCharacterWithSoul(uint256 targetId, uint256 soulAmount) public burningEnabled {
        require(userVars[msg.sender][USERVAR_SOUL_SUPPLY] >= soulAmount, 'Not enough soul');
        userVars[msg.sender][USERVAR_SOUL_SUPPLY] = userVars[msg.sender][USERVAR_SOUL_SUPPLY].sub(soulAmount);
        characters.upgradeWithSoul(targetId, soulAmount);
    }

    // VARS SETTER

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }
}
