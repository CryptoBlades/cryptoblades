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
    uint256 public constant VARS_SOUL_SUPPLY = 1;

    function initialize(Characters _characters, Garrison _garrison, CryptoBlades _game)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

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

    // VIEWS

    function burnCharactersFee(uint256[] memory burnIds) public view returns (uint256) {
        uint256 burnFee = 0;
        for(uint i = 0; i < burnIds.length; i++) {
            burnFee += burnCharacterFee(burnIds[i]);
        }
        return burnFee;
    }

    function burnCharacterFee(uint256 burnId) public view returns (uint256) {
        return (game.vars(game.VAR_HOURLY_PAY_PER_FIGHT()) / game.vars(game.VAR_HOURLY_MAX_POWER_AVERAGE())) * 7 * characters.getTotalPower(burnId) * 60;
    }

    //FUNCTIONS

    function burnCharacterFromMarket(uint256 burnId) external {
        require(hasRole(BURNER_ROLE, msg.sender), 'Not burner');
        game.payContractTokenOnly(tx.origin, burnCharacterFee(burnId));
        uint256[] memory burnIds = new uint256[](1);
        burnIds[0] = burnId;
        userVars[tx.origin][VARS_SOUL_SUPPLY] += characters.getSoulForBurns(burnIds);
        characters.burnIntoSoul(burnIds);
    }

    function burnCharactersIntoCharacter(uint256[] memory burnIds, uint256 targetId) public isCharactersOwner(burnIds) {
        game.payContractTokenOnly(msg.sender, burnCharactersFee(burnIds));
        characters.burnIntoCharacter(burnIds, targetId);
    }

    function burnCharactersIntoSoul(uint256[] memory burnIds) public isCharactersOwner(burnIds) {
        game.payContractTokenOnly(msg.sender, burnCharactersFee(burnIds));
        userVars[msg.sender][VARS_SOUL_SUPPLY] += characters.getSoulForBurns(burnIds);
        characters.burnIntoSoul(burnIds);
    }

    function upgradeCharacterWithSoul(uint256 targetId, uint256 soulAmount) public {
        require(userVars[msg.sender][VARS_SOUL_SUPPLY] >= soulAmount, 'Not enough soul');
        userVars[msg.sender][VARS_SOUL_SUPPLY] = userVars[msg.sender][VARS_SOUL_SUPPLY].sub(soulAmount);
        characters.upgradeWithSoul(targetId, soulAmount);
    }
}
