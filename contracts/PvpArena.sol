pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./util.sol";
import "./interfaces/IRandoms.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./shields.sol";
import "./raid1.sol";

contract PvpArena is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;
    using SafeMath for uint8;

    struct Fighter {
        uint256 characterID;
        uint256 weaponID;
        uint256 shieldID;
        /// @dev amount of skill wagered for this character
        uint256 wager;
        uint256 lockedWager;
        bool useShield;
    }
    struct Duel {
        uint256 attackerID;
        uint256 defenderID;
        uint256 createdAt;
    }

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    Shields public shields;
    IERC20 public skillToken;
    Raid1 public raids;
    IRandoms public randoms;

    /// @dev the base amount wagered per duel in dollars
    int128 private _baseWagerUSD;
    /// @dev how much extra USD is wagered per level tier
    int128 private _tierWagerUSD;
    /// @dev how many times the cost of battling must be wagered to enter the arena
    uint256 public wageringFactor;
    /// @dev amount of time a character is unattackable
    uint256 public unattackableSeconds;
    /// @dev amount of time an attacker has to make a decision
    uint256 public decisionSeconds;

    /// @dev last time a character was involved in activity that makes it untattackable
    mapping(uint256 => uint256) private _lastActivityByCharacter;
    /// @dev Fighter by characterID
    mapping(uint256 => Fighter) private _fightersByCharacter;
    /// @dev IDs of characters available by tier (1-10, 11-20, etc...)
    mapping(uint8 => uint256[]) private _fightersByTier;
    /// @dev IDs of characters in the arena per player
    mapping(address => uint256[]) private _fightersByPlayer;
    /// @dev Active duel by characterID currently attacking
    mapping(uint256 => Duel) private _duelByAttacker;
    ///@dev characters currently in the arena
    mapping(uint256 => bool) private _charactersInArena;
    ///@dev weapons currently in the arena
    mapping(uint256 => bool) private _weaponsInArena;
    ///@dev shields currently in the arena
    mapping(uint256 => bool) private _shieldsInArena;

    event NewDuel(
        uint256 indexed attacker,
        uint256 indexed defender,
        uint256 timestamp
    );

    modifier characterInArena(uint256 characterID) {
        require(
            isCharacterInArena(characterID),
            "Character is not in the arena"
        );
        _;
    }
    modifier isOwnedCharacter(uint256 characterID) {
        require(
            characters.ownerOf(characterID) == msg.sender,
            "Character is not owned by sender"
        );
        _;
    }

    modifier enteringArenaChecks(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) {
        require(!isCharacterInArena(characterID), "Character already in arena");
        require(!_weaponsInArena[weaponID], "Weapon already in arena");
        require(
            characters.ownerOf(characterID) == msg.sender,
            "Not character owner"
        );
        require(weapons.ownerOf(weaponID) == msg.sender, "Not weapon owner");
        require(!raids.isCharacterRaiding(characterID), "Character is in raid");
        require(!raids.isWeaponRaiding(weaponID), "Weapon is in raid");

        if (useShield) {
            require(
                shields.ownerOf(shieldID) == msg.sender,
                "Not shield owner"
            );
            require(!_shieldsInArena[shieldID], "Shield already in arena");
        }

        _;
    }

    function initialize(
        address gameContract,
        address shieldsContract,
        address raidContract,
        address randomsContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        shields = Shields(shieldsContract);
        skillToken = IERC20(game.skillToken());
        raids = Raid1(raidContract);
        randoms = IRandoms(randomsContract);

        // TODO: Tweak these values, they are placeholders
        wageringFactor = 3;
        _baseWagerUSD = ABDKMath64x64.divu(500, 100); // $5
        _tierWagerUSD = ABDKMath64x64.divu(50, 100); // $0.5
        unattackableSeconds = 2 minutes;
        decisionSeconds = 3 minutes;
    }

    /// @notice enter the arena with a character, a weapon and optionally a shield
    function enterArena(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) external enteringArenaChecks(characterID, weaponID, shieldID, useShield) {
        uint256 wager = getEntryWager(characterID);
        uint8 tier = getArenaTier(characterID);

        _charactersInArena[characterID] = true;
        _weaponsInArena[weaponID] = true;

        if (useShield) _shieldsInArena[shieldID] = true;

        _fightersByTier[tier].push(characterID);
        _fightersByPlayer[msg.sender].push(characterID);
        _fightersByCharacter[characterID] = Fighter(
            characterID,
            weaponID,
            shieldID,
            wager,
            0,
            useShield
        );

        // character starts unattackable
        _updateLastActivityTimestamp(characterID);

        skillToken.transferFrom(msg.sender, address(this), wager);
    }

    /// @dev attempts to find an opponent for a character. If a battle is still pending, it charges a penalty and re-rolls the opponent
    function requestOpponent(uint256 characterID)
        external
        characterInArena(characterID)
        isOwnedCharacter(characterID)
    {
        uint8 tier = getArenaTier(characterID);

        uint256[] storage fightersInTier = _fightersByTier[tier];

        require(
            fightersInTier.length != 0,
            "No opponents available for this character's level"
        );

        uint256 seed = randoms.getRandomSeed(msg.sender);
        uint256 randomIndex = RandomUtil.randomSeededMinMax(
            0,
            fightersInTier.length - 1,
            seed
        );

        uint256 opponentID;
        bool foundOpponent = false;

        // run through fighters from a random starting point until we find one or none are available
        for (uint256 i = 0; i < fightersInTier.length; i++) {
            uint256 index = (randomIndex + i) % fightersInTier.length;
            uint256 candidateID = fightersInTier[index];
            if (candidateID == characterID) continue;
            if (!isCharacterAttackable(candidateID)) continue;
            foundOpponent = true;
            opponentID = candidateID;
            break;
        }

        require(foundOpponent, "No opponent found");

        _duelByAttacker[characterID] = Duel(
            characterID,
            opponentID,
            block.timestamp
        );

        // lock the cost of the duel
        _fightersByCharacter[characterID].lockedWager = getDuelCost(
            characterID
        );

        // mark both characters as unattackable
        _lastActivityByCharacter[characterID] = block.timestamp;
        _lastActivityByCharacter[opponentID] = block.timestamp;

        emit NewDuel(characterID, opponentID, block.timestamp);
    }

    /// @dev performs a given character's duel against its opponent
    function performDuel(uint256 characterID) external {
        // TODO: implement (not final signature)
    }

    /// @dev withdraws a character from the arena.
    /// if the character is in a battle, a penalty is charged
    function withdrawCharacter(uint256 characterID) external {
        // TODO: implement (not final signature)
    }

    /// @dev requests a new opponent for a fee
    function reRollOpponent(uint256 characterID) external {
        // TODO:
        // - [ ] check if character is currently attacking
        // - [ ] check if penalty can be paid
        // - [ ] charge penalty
        // - [ ] find a new opponent
    }

    /// @dev gets the amount of SKILL that is risked per duel
    function getDuelCost(uint256 characterID) public view returns (uint256) {
        int128 tierExtra = ABDKMath64x64
            .divu(getArenaTier(characterID).mul(100), 100)
            .mul(_tierWagerUSD);

        return game.usdToSkill(_baseWagerUSD.add(tierExtra));
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
        return _fightersByPlayer[msg.sender];
    }

    /// @dev returns the senders fighters in the arena
    function _getMyFighters() internal view returns (Fighter[] memory) {
        uint256[] memory characterIDs = getMyParticipatingCharacters();
        Fighter[] memory fighters = new Fighter[](characterIDs.length);

        for (uint256 i = 0; i < characterIDs.length; i++) {
            fighters[i] = _fightersByCharacter[characterIDs[i]];
        }

        return fighters;
    }

    /// @dev returns the IDs of the sender's weapons currently in the arena
    function getMyParticipatingWeapons()
        external
        view
        returns (uint256[] memory)
    {
        Fighter[] memory fighters = _getMyFighters();
        uint256[] memory weaponIDs = new uint256[](fighters.length);

        for (uint256 i = 0; i < fighters.length; i++) {
            weaponIDs[i] = fighters[i].weaponID;
        }

        return weaponIDs;
    }

    /// @dev returns the IDs of the sender's shields currently in the arena
    function getMyParticipatingShields()
        external
        view
        returns (uint256[] memory)
    {
        Fighter[] memory fighters = _getMyFighters();
        uint256 shieldsCount = 0;

        for (uint256 i = 0; i < fighters.length; i++) {
            if (fighters[i].useShield) shieldsCount++;
        }

        uint256[] memory shieldIDs = new uint256[](shieldsCount);
        uint256 shieldIDsIndex = 0;

        for (uint256 i = 0; i < fighters.length; i++) {
            if (fighters[i].useShield) {
                shieldIDs[shieldIDsIndex] = fighters[i].shieldID;
                shieldIDsIndex++;
            }
        }

        return shieldIDs;
    }

    /// @dev checks if a character is in the arena
    function isCharacterInArena(uint256 characterID)
        public
        view
        returns (bool)
    {
        return _charactersInArena[characterID];
    }

    /// @dev checks if a weapon is in the arena
    function isWeaponInArena(uint256 weaponID) public view returns (bool) {
        return _weaponsInArena[weaponID];
    }

    /// @dev checks if a shield is in the arena
    function isShieldInArena(uint256 shieldID) public view returns (bool) {
        return _shieldsInArena[shieldID];
    }

    /// @dev get a character's amount of wager that is locked
    function getLockedWager(uint256 characterID) public view returns (uint256) {
        return _fightersByCharacter[characterID].lockedWager;
    }

    /// @dev get an attacker's opponent
    function getOpponent(uint256 characterID) public view returns (uint256) {
        return _duelByAttacker[characterID].defenderID;
    }

    /// @dev wether or not the character is still in time to start a duel
    function isAttackerWithinDecisionTime(uint256 characterID)
        public
        view
        returns (bool)
    {
        return
            _duelByAttacker[characterID].createdAt.add(decisionSeconds) >
            block.timestamp;
    }

    /// @dev wether or not a character can appear as someone's opponent
    function isCharacterAttackable(uint256 characterID)
        public
        view
        returns (bool)
    {
        uint256 lastActivity = _lastActivityByCharacter[characterID];

        return lastActivity.add(unattackableSeconds) <= block.timestamp;
    }

    /// @dev updates the last activity timestamp of a character
    function _updateLastActivityTimestamp(uint256 characterID) private {
        _lastActivityByCharacter[characterID] = block.timestamp;
    }
}
