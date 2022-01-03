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
    uint256 public burnCharacterFee;

    function initialize(Characters _characters, Garrison _garrison, CryptoBlades _game, uint256 _burnCharacterFee)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        characters = _characters;
        garrison = _garrison;
        game = _game;
        burnCharacterFee = _burnCharacterFee;
    }

    // MODIFIERS

    modifier isCharacterOwner(uint256 burnId) {
        _isCharacterOwner(burnId);
        _;
    }

    function _isCharacterOwner(uint256 burnId) internal view {
        require(hasRole(BURNER_ROLE, msg.sender) || characters.ownerOf(burnId) == msg.sender || garrison.getCharacterOwner(burnId) == msg.sender, 'Not owner');
    }

    modifier isCharactersOwner(uint256[] memory burnIds) {
        _isCharactersOwner(burnIds);
        _;
    }

    function _isCharactersOwner(uint256[] memory burnIds) internal view {
        for(uint i = 0; i < burnIds.length; i++) {
            require(hasRole(BURNER_ROLE, msg.sender) || characters.ownerOf(burnIds[i]) == msg.sender || garrison.getCharacterOwner(burnIds[i]) == msg.sender, 'Not owner');
        }
    }

    //FUNCTIONS

    function burnCharacterIntoCharacter(uint256 burnId, uint256 targetId) external isCharacterOwner(burnId) {
        game.payContractTokenOnly(msg.sender, burnCharacterFee);
        characters.burnIntoCharacter(burnId, targetId);
    }

    function burnCharacterIntoSoul(uint256 burnId) external isCharacterOwner(burnId) {
        game.payContractTokenOnly(msg.sender, burnCharacterFee);
        characters.burnIntoSoul(burnId, msg.sender);
    }

    function burnCharacterFromMarket(uint256 burnId) external isCharacterOwner(burnId) {
        game.payContractTokenOnly(tx.origin, burnCharacterFee);
        characters.burnIntoSoul(burnId, tx.origin);
    }

    function burnCharactersIntoCharacter(uint256[] memory burnIds, uint256 targetCharId) public isCharactersOwner(burnIds) {
        game.payContractTokenOnly(msg.sender, burnCharacterFee.mul(burnIds.length));
        for(uint i = 0; i < burnIds.length; i++) {
            characters.burnIntoCharacter(burnIds[i], targetCharId);
        }
    }

    function burnCharactersIntoSoul(uint256[] memory burnIds) public isCharactersOwner(burnIds) {
        game.payContractTokenOnly(msg.sender, burnCharacterFee.mul(burnIds.length));
        for(uint i = 0; i < burnIds.length; i++) {
            characters.burnIntoSoul(burnIds[i], msg.sender);
        }
    }
}
