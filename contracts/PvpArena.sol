pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";

// TODO:
// - [ ] use proper types for costs
contract PvpArena is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;

    struct Fighter {
        uint256 characterID;
        uint256 weaponID;
        uint256 wager;
    }

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    IERC20 public skillToken;

    /// @dev fighters available by level
    mapping (uint256 => Fighter[]) private fightersByLevel;
    /// @dev the base cost required to enter the arena
    int128 public baseEntryCost;
    /// @dev additional cost per character level
    int128 public extraCostPerLevel;


    function initialize(address gameContract) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        skillToken = IERC20(game.skillToken());

        // TODO: define the real values
        baseEntryCost = 2;
        extraCostPerLevel = ABDKMath64x64.divu(1, 10);
    }

    /// @dev enter the arena with a character and a weapon
    function enterArena(uint256 characterID, uint256 weaponID) public {
        // TODOS:
        // - [ ] check if character is not in the arena
        // - [ ] check if weapon is not in the arena
        // - [x] calculate wager cost
        // - [ ] check if character is sender's
        uint256 entryCost = getEntryCost(characterID);

        skillToken.transferFrom(msg.sender, address(this), entryCost);
    }

    /// @dev get the amount of SKILL required to enter the arena
    /// @param characterID the id of the character entering the arena
    function getEntryCost(uint256 characterID) public view returns (uint256) {
        int128 costInUsd = ABDKMath64x64.fromUInt(extraCostPerLevel.mulu(characters.getLevel(characterID))).add(baseEntryCost);
        return game.usdToSkill(costInUsd);
    }

}