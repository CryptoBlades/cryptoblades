pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/IRandoms.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./shields.sol";

contract PvpArena is Initializable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint8;
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;

    struct Fighter {
        uint256 characterID;
        uint256 weaponID;
        uint256 shieldID;
        uint256 wager;
        bool useShield;
    }

    struct Match {
        uint256 attackerID;
        uint256 defenderID;
        uint256 createdAt;
        bool isPending;
    }

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    Shields public shields;
    IERC20 public skillToken;
    IRandoms public randoms;

    /// @dev the base amount wagered per duel in dollars
    int128 private _baseWagerUSD;
    /// @dev how much extra USD is wagered per level tier
    int128 private _tierWagerUSD;
    /// @dev how much of a duel's bounty is sent to the rankings pool
    uint8 private _rankingsPoolTaxPercent;
    /// @dev how many times the cost of battling must be wagered to enter the arena
    uint8 public wageringFactor;
    /// @dev amount of points earned by winning a duel
    uint8 public winningPoints;
    /// @dev amount of points subtracted by losing duel
    uint8 public losingPoints;
    /// @dev max amount of top characters by tier
    uint8 private _maxTopCharactersPerTier;
    /// @dev percentage of duel cost charged when rerolling opponent
    uint256 public reRollFeePercent;
    /// @dev percentage of entry wager charged when withdrawing from arena with pending duel
    uint256 public withdrawFeePercent;
    /// @dev current ranked season
    uint256 public currentRankedSeason;
    /// @dev timestamp of when the current season started
    uint256 public seasonStartedAt;
    /// @dev interval of ranked season restarts
    uint256 public seasonDuration;
    /// @dev minimum amount of seconds a character is in the cooldown queue
    uint256 public cooldownSeconds;
    /// @dev amount of time a match finder has to make a decision
    uint256 public decisionSeconds;
    /// @dev amount of skill due for game coffers from tax
    uint256 public gameCofferTaxDue;
    /// @dev allows or blocks entering arena (we can extend later to disable other parts such as rerolls)
    uint256 public arenaAccess; // 0 = cannot join, 1 = can join
    /// @dev percentages of ranked prize distribution by fighter rank (represented as index)
    uint256[] public prizePercentages;
    /// @dev characters by id that are on queue to perform a duel
    EnumerableSet.UintSet private _duelQueue;

    /// @dev Fighter by characterID
    mapping(uint256 => Fighter) public fighterByCharacter;
    /// @dev Active match by characterID of the finder
    mapping(uint256 => Match) public matchByFinder;
    /// @dev if character is currently in the arena
    mapping(uint256 => bool) private _isCharacterInArena;
    /// @dev if weapon is currently in the arena
    mapping(uint256 => bool) private _isWeaponInArena;
    /// @dev if shield is currently in the arena
    mapping(uint256 => bool) private _isShieldInArena;
    /// @dev if defender is in a duel that has not finished processing
    mapping(uint256 => bool) public isDefending;
    /// @dev character's tier when it last entered arena. Used to reset rank if it changes
    mapping(uint256 => uint8) public previousTierByCharacter;
    /// @dev excess wager by character for when they re-enter the arena
    mapping(uint256 => uint256) public excessWagerByCharacter;
    /// @dev season number associated to character
    mapping(uint256 => uint256) public seasonByCharacter;
    /// @dev ranking points by character
    mapping(uint256 => uint256) public rankingPointsByCharacter;
    /// @dev funds available for withdrawal by address
    mapping(address => uint256) private _rankingRewardsByPlayer;
    /// @dev top ranking characters by tier
    mapping(uint8 => uint256[]) private _topRankingCharactersByTier;
    /// @dev IDs of characters available for matchmaking by tier
    mapping(uint8 => EnumerableSet.UintSet) private _matchableCharactersByTier;

    event DuelFinished(
        uint256 indexed attacker,
        uint256 indexed defender,
        uint256 timestamp,
        uint256 attackerRoll,
        uint256 defenderRoll,
        bool attackerWon
    );

    modifier characterInArena(uint256 characterID) {
        _characterInArena(characterID);
        _;
    }
    
    function _characterInArena(uint256 characterID) internal view {
        require(
            isCharacterInArena(characterID),
            "Char not in the arena"
        );
    }

    modifier isOwnedCharacter(uint256 characterID) {
        require(
            characters.ownerOf(characterID) == msg.sender);
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not admin");
    }

    modifier enteringArenaChecks(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) {
        require(characters.ownerOf(characterID) == msg.sender
            && weapons.ownerOf(weaponID) == msg.sender);

        require(characters.getNftVar(characterID, 1) == 0, "Char busy");
        require(weapons.getNftVar(weaponID, 1) == 0, "Wpn busy");

        if (useShield) {
            require(shields.ownerOf(shieldID) == msg.sender);
            require(shields.getNftVar(shieldID, 1) == 0, "Shld busy");
        }

        require((arenaAccess & 1) == 1, "Arena locked");
        _;
    }

    function initialize(
        address gameContract,
        address shieldsContract,
        address randomsContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        shields = Shields(shieldsContract);
        skillToken = IERC20(game.skillToken());
        randoms = IRandoms(randomsContract);

        // TODO: Tweak these values
        _baseWagerUSD = ABDKMath64x64.divu(500, 100); // $5
        _tierWagerUSD = ABDKMath64x64.divu(50, 100); // $0.5
        _rankingsPoolTaxPercent = 15;
        wageringFactor = 3;
        winningPoints = 5;
        losingPoints = 3;
        _maxTopCharactersPerTier = 4;
        reRollFeePercent = 25;
        withdrawFeePercent = 25;
        currentRankedSeason = 1;
        seasonStartedAt = block.timestamp;
        seasonDuration = 1 days;
        cooldownSeconds = 2 minutes;
        decisionSeconds = 2 minutes;
        prizePercentages.push(60);
        prizePercentages.push(30);
        prizePercentages.push(10);
    }

    /// @dev enter the arena with a character, a weapon and optionally a shield
    function enterArena(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) external enteringArenaChecks(characterID, weaponID, shieldID, useShield) {
        // TODO: Fill
        uint256 wager = getEntryWager(characterID);
        uint8 tier = getArenaTier(characterID);

        if (previousTierByCharacter[characterID] != getArenaTier(characterID)) {
            rankingPointsByCharacter[characterID] = 0;
        }

        if (_topRankingCharactersByTier[tier].length < _maxTopCharactersPerTier && seasonByCharacter[characterID] != currentRankedSeason) {
            _topRankingCharactersByTier[tier].push(characterID);
        }

        if (seasonByCharacter[characterID] != currentRankedSeason) {
            rankingPointsByCharacter[characterID] = 0;
            seasonByCharacter[characterID] = currentRankedSeason;
        }

        _isCharacterInArena[characterID] = true;
        _isWeaponInArena[characterID] = true;
        if (useShield) {
            _isShieldInArena[shieldID] = true;
        }

        _matchableCharactersByTier[tier].add(characterID);
        fighterByCharacter[characterID] = Fighter(
            characterID,
            weaponID,
            shieldID,
            wager.add(getCharacterWager(characterID)),
            useShield  
        );
        previousTierByCharacter[characterID] = getArenaTier(characterID);
        excessWagerByCharacter[characterID] = 0;

        skillToken.transferFrom(msg.sender, address(this), wager);

        characters.setNftVar(characterID, 1, 1);
        weapons.setNftVar(weaponID, 1, 1);
        if (useShield) {
            shields.setNftVar(shieldID, 1, 1);
        }
    }

    /// @dev checks if a character is in the arena
    function isCharacterInArena(uint256 characterID)
        public
        view
        returns (bool)
    {
        return _isCharacterInArena[characterID];
    }

    /// @dev gets the amount of SKILL required to enter the arena
    function getEntryWager(uint256 characterID) public view returns (uint256) {
        return getDuelCost(characterID).mul(wageringFactor);
    }

    /// @dev get's a characters current wager
    function getCharacterWager(uint256 characterID)
        public
        view
        returns (uint256)
    {
        if (excessWagerByCharacter[characterID] != 0) {
            return excessWagerByCharacter[characterID];
        }

        return fighterByCharacter[characterID].wager;
    }

    /// @dev gets the amount of SKILL that is risked per duel
    function getDuelCost(uint256 characterID) public view returns (uint256) {
        int128 tierExtra = ABDKMath64x64
            .divu(getArenaTier(characterID).mul(100), 100)
            .mul(_tierWagerUSD);

        return game.usdToSkill(_baseWagerUSD.add(tierExtra));
    }

    /// @dev gets the arena tier of a character (tiers are 1-10, 11-20, etc...)
    function getArenaTier(uint256 characterID) public view returns (uint8) {
        uint256 level = characters.getLevel(characterID);
        return uint8(level.div(10));
    }
}