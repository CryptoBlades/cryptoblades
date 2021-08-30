pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./shields.sol";
import "./raid1.sol";

// TODO:
// - [ ] use proper types for costs
contract PvpArena is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    struct Fighter {
        uint256 characterID;
        uint256 weaponID;
        uint256 shieldID;
        /// @dev amount of skill wagered for this character
        uint256 wagerAmount;
        bool useShield;
    }

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    Shields public shields;
    IERC20 public skillToken;
    Raid1 public raids;

    /// @dev how many times the cost of battling must be wagered to enter the arena
    uint256 wageringFactor;

    /// @dev fighters available by tier (1-10, 11-20, etc...)
    mapping(uint8 => Fighter[]) private fightersByTier;
    /// @dev fighters by player address
    mapping(address => Fighter[]) private fightersByPlayer;

    ///@dev mapping to track the characters used
    mapping(uint256 => bool) public charactersInUse;

    ///@dev mapping to track the weapons used
    mapping(uint256 => bool) public weaponsInUse;

    ///@dev mapping to track the shields used
    mapping(uint256 => bool) public shieldsInUse;

    modifier enteringArenaChecks(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) {
        require(
            !charactersInUse[characterID],
            "The character is already in the arena"
        );
        require(
            !weaponsInUse[characterID],
            "The weapon is already in the arena"
        );
        require(
            characters.ownerOf(characterID) == msg.sender,
            "You don't own the given character"
        );
        require(
            weapons.ownerOf(weaponID) == msg.sender,
            "You don't own the given weapon"
        );
        require(
            !raids.isCharacterRaiding(characterID),
            "The given character is already raiding"
        );
        require(
            !raids.isWeaponRaiding(weaponID),
            "The given weapon is already raiding"
        );

        if (useShield) {
            require(
                shields.ownerOf(shieldID) == msg.sender,
                "You don't own the given shield"
            );
            require(
                !shieldsInUse[shieldID],
                "The shield is already in the arena"
            );
            // TODO: Check if shields are used in the arena somehow
        }

        _;
    }

    function initialize(
        address gameContract,
        address shieldContract,
        address raidContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        shields = Shields(shieldContract);
        skillToken = IERC20(game.skillToken());
        raids = Raid1(raidContract);

        wageringFactor = 3;
    }

    /// @notice enter the arena with a character, a weapon and a shield(optional)
    function enterArena(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) public enteringArenaChecks(characterID, weaponID, shieldID, useShield) {
        uint256 wager = getEntryWager(characterID);
        uint8 tier = getArenaTier(characterID);

        charactersInUse[characterID] = true;
        weaponsInUse[weaponID] = true;

        if (useShield) shieldsInUse[shieldID] = true;

        Fighter memory fighter = Fighter(
            characterID,
            weaponID,
            shieldID,
            wager,
            useShield
        );

        fightersByTier[tier].push(fighter);
        fightersByPlayer[msg.sender].push(fighter);

        skillToken.transferFrom(msg.sender, address(this), wager);
    }

    /// @notice gets the amount of SKILL that is risked per duel
    function getDuelCost(uint256 characterID) public view returns (uint256) {
        // FIXME: Use normal combat rewards formula. THIS IS JUST TEMPORARY CODE
        return getArenaTier(characterID).add(1).mul(1000);
    }

    /// @notice gets the amount of SKILL required to enter the arena
    /// @param characterID the id of the character entering the arena
    function getEntryWager(uint256 characterID) public view returns (uint256) {
        return getDuelCost(characterID).mul(wageringFactor);
    }

    /// @dev gets the arena tier of a character (tiers are 1-10, 11-20, etc...)
    function getArenaTier(uint256 characterID) public view returns (uint8) {
        uint256 level = characters.getLevel(characterID);

        return uint8(level.div(10));
    }

    /// @dev gets IDs of the sender's characters currently in the arena
    function getMyParticipatingCharacters()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids;

        for (uint256 i = 0; i < fightersByPlayer[msg.sender].length; i++) {
            ids[i] = fightersByPlayer[msg.sender][i].characterID;
        }

        return ids;
    }

    /// @dev attempts to find an opponent for a character. If a battle is still pending, it charges a penalty and re-rolls the opponent
    function requestOpponent(uint256 characterID) public returns (uint256) {
        // TODO: implement (not final signature)
    }

    /// @dev checks if a character is in the arena
    function isCharacterInArena(uint256 characterID)
        public
        view
        returns (bool)
    {
        return charactersInUse[characterID];
    }

    /// @dev checks if a weapon is in the arena
    function isWeaponInArena(uint256 weaponID) public view returns (bool) {
        return weaponsInUse[weaponID];
    }

    /// @dev checks if a shield is in the arena
    function isShieldInArena(uint256 shieldID) public view returns (bool) {
        return shieldsInUse[shieldID];
    }

    /// @dev performs a given character's duel against its opponent
    function performDuel(uint256 characterID) public {
        // TODO: implement (not final signature)
    }

    /// @dev withdraws a character from the arena.
    /// if the character is in a battle, a penalty is charged
    function withdrawCharacter(uint256 characterID) public {
        // TODO: implement (not final signature)
    }
}
