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
    using SafeERC20 for IERC20;


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
    // TODO: USE THIS!!
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
    /// @dev accumulated skill pool per tier
    mapping(uint8 => uint256) private _rankingsPoolByTier;
    /// @dev IDs of characters available for matchmaking by tier
    mapping(uint8 => EnumerableSet.UintSet) private _matchableCharactersByTier;

    // Note: we might want the NewDuel (NewMatch) event

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
            "Char not in arena"
        );
    }

    modifier characterWithinDecisionTime(uint256 characterID) {
        _characterWithinDecisionTime(characterID);
        _;
    }
    
    function _characterWithinDecisionTime(uint256 characterID) internal view {
        require(
            isCharacterWithinDecisionTime(characterID),
            "Decision time expired"
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
        characters.setNftVar(characterID, 1, 1);

        _isWeaponInArena[characterID] = true;
        weapons.setNftVar(weaponID, 1, 1);

        if (useShield) {
            _isShieldInArena[shieldID] = true;
            shields.setNftVar(shieldID, 1, 1);
        }

        uint256 characterWager;

        if (excessWagerByCharacter[characterID] != 0) {
            characterWager = excessWagerByCharacter[characterID];
        } else {
            characterWager = fighterByCharacter[characterID].wager;
        }

        _matchableCharactersByTier[tier].add(characterID);
        fighterByCharacter[characterID] = Fighter(
            characterID,
            weaponID,
            shieldID,
            wager.add(characterWager),
            useShield  
        );
        previousTierByCharacter[characterID] = getArenaTier(characterID);
        excessWagerByCharacter[characterID] = 0;

        skillToken.transferFrom(msg.sender, address(this), wager);
    }

    /// @dev withdraws a character and its items from the arena.
    /// if the character is in a battle, a penalty is charged
    function withdrawFromArena(uint256 characterID) 
        external
        isOwnedCharacter(characterID)
        characterInArena(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];
        uint256 wager = fighter.wager;
        uint256 entryWager = getEntryWager(characterID);

        if (matchByFinder[characterID].createdAt != 0) {
            if (wager < entryWager.mul(withdrawFeePercent).div(100)) {
                wager = 0;
            } else {
                wager = wager.sub(entryWager.mul(withdrawFeePercent).div(100));
            }
        }

        _removeCharacterFromArena(characterID);

        excessWagerByCharacter[characterID] = 0;
        fighter.wager = 0;

        skillToken.safeTransfer(msg.sender, wager);
    }

    /// @dev attepts to find an opponent for a character
    function findOpponent(uint256 characterID)
        external
        characterInArena(characterID)
        isOwnedCharacter(characterID)
    {
        require(matchByFinder[characterID].createdAt == 0, "Already in match");

        _assignOpponent(characterID);
    }

    /// @dev attempts to find a new opponent for a fee
    function reRollOpponent(uint256 characterID)
        external
        characterInArena(characterID)
        isOwnedCharacter(characterID)
    {
        require(matchByFinder[characterID].createdAt != 0, "Not in match");

        _assignOpponent(characterID);

        skillToken.transferFrom(
            msg.sender,
            address(this),
            getDuelCost(characterID).mul(reRollFeePercent).div(100)
        );
    }

    /// @dev adds a character to the duel queue
    function prepareDuel(uint256 attackerID)
        external
        isOwnedCharacter(attackerID)
        characterInArena(attackerID)
        characterWithinDecisionTime(attackerID)
    {
        require(!_duelQueue.contains(attackerID), "Char in duel queue");

        uint256 defenderID = getOpponent(attackerID);

        if (seasonByCharacter[attackerID] != currentRankedSeason) {
            rankingPointsByCharacter[attackerID] = 0;
            seasonByCharacter[attackerID] = currentRankedSeason;
        }

        if (seasonByCharacter[defenderID] != currentRankedSeason) {
            rankingPointsByCharacter[defenderID] = 0;
            seasonByCharacter[defenderID] = currentRankedSeason;
        }

        isDefending[defenderID] = true;

        _duelQueue.add(attackerID);
    }

    /// @dev allows a player to withdraw their ranking earnings
    function withdrawRankedRewards() external {
        uint256 amountToTransfer = _rankingRewardsByPlayer[msg.sender];

        if (amountToTransfer > 0) {
            _rankingRewardsByPlayer[msg.sender] = 0;

            skillToken.safeTransfer(msg.sender, amountToTransfer);
        }
    }

    /// @dev restarts ranked season
    function restartRankedSeason() public restricted {
        uint256[] memory duelQueue = getDuelQueue();

        if (duelQueue.length > 0) {
            performDuels(duelQueue);
        }

        // Loops over 15 tiers. Should not be reachable anytime in the foreseeable future
        for (uint8 i = 0; i <= 15; i++) {
            if (_topRankingCharactersByTier[i].length == 0) {
                continue;
            }

            uint256 difference = 0;

            if (_topRankingCharactersByTier[i].length <= prizePercentages.length) {
                difference = prizePercentages.length - _topRankingCharactersByTier[i].length;
            }

            // If there are less players than top positions, excess is transferred to top 1
            if (_topRankingCharactersByTier[i].length < prizePercentages.length) {
                uint256 excessPercentage;
                address topOnePlayer = characters.ownerOf(_topRankingCharactersByTier[i][0]);

                // We accumulate excess percentage
                for (
                    uint256 j = prizePercentages.length - difference;
                    j < prizePercentages.length;
                    j++
                ) {
                    excessPercentage = excessPercentage.add(
                        prizePercentages[j]
                    );
                }

                // We assign excessive rewards to top 1 player
                _rankingRewardsByPlayer[
                    topOnePlayer
                ] = _rankingRewardsByPlayer[topOnePlayer].add(
                    (_rankingsPoolByTier[i].mul(excessPercentage)).div(100)
                );
            }

            // We assign rewards normally to all possible players
            for (uint8 h = 0; h < prizePercentages.length - difference; h++) {
                _assignRewards(_topRankingCharactersByTier[i][h], h, _rankingsPoolByTier[i]);
            }

            // We reset ranking prize pools
            _rankingsPoolByTier[i] = 0;

            // We reset top players' scores
            for (uint256 k = 0; k < 4; k++) {
                rankingPointsByCharacter[_topRankingCharactersByTier[i][k]] = 0;
            }
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

    /// @dev wether or not the character is still in time to start a duel
    function isCharacterWithinDecisionTime(uint256 characterID)
        public
        view
        returns (bool)
    {
        return
            matchByFinder[characterID].createdAt.add(decisionSeconds) >
            block.timestamp;
    }

    /// @dev gets the amount of SKILL required to enter the arena
    function getEntryWager(uint256 characterID) public view returns (uint256) {
        return getDuelCost(characterID).mul(wageringFactor);
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

    /// @dev get an attacker's opponent
    function getOpponent(uint256 attackerID) 
        public
        view
        characterWithinDecisionTime(attackerID)
        returns (uint256) 
    {
        return matchByFinder[attackerID].defenderID;
    }

    /// @dev gets the accumulated ranking rewards pool per tier
    function getRankingRewardsPool(uint8 tier) public view returns (uint256) {
        return _rankingsPoolByTier[tier];
    }

    /// @dev get the top ranked characters by a character's ID
    function getTierTopCharacters(uint256 characterID)
        public
        view
        returns (uint256[] memory)
    {
        uint8 tier = getArenaTier(characterID);
        uint256 arrayLength;
        // we return only the top 3 players, returning the array without the pivot ranker if it exists
        if (_topRankingCharactersByTier[tier].length == _maxTopCharactersPerTier) {
            arrayLength = _topRankingCharactersByTier[tier].length - 1;
        } else {
            arrayLength = _topRankingCharactersByTier[tier].length;
        }
        uint256[] memory topRankers = new uint256[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            topRankers[i] = _topRankingCharactersByTier[tier][i];
        }

        return topRankers;
    }

    /// @dev returns ranked prize percentages distribution
    function getPrizePercentages() external view returns (uint256[] memory) {
        return prizePercentages;
    }

    /// @dev returns the account's ranking prize pool earnings
    function getPlayerPrizePoolRewards() view public returns(uint256){
        return _rankingRewardsByPlayer[msg.sender];
    }

    /// @dev returns the current duel queue
    function getDuelQueue() public view returns (uint256[] memory) {
        uint256 length = _duelQueue.length();
        uint256[] memory values = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = _duelQueue.at(i);
        }

        return values;
    }

    /// @dev assigns an opponent to a character
    function _assignOpponent(uint256 characterID) private {
        uint8 tier = getArenaTier(characterID);
        EnumerableSet.UintSet storage matchableCharacters = _matchableCharactersByTier[tier];

        require(matchableCharacters.length() != 0, "No enemy in tier");
        require(!_duelQueue.contains(characterID), "Char dueling");

        uint256 seed = randoms.getRandomSeed(msg.sender);
        uint256 randomIndex = RandomUtil.randomSeededMinMax(
            0,
            matchableCharacters.length() - 1,
            seed
        );
        uint256 opponentID;
        uint256 matchableCharactersCount = matchableCharacters.length(); 
        bool foundOpponent = false;

        for (uint256 i = 0; i < matchableCharactersCount; i++) {
            uint256 index = (randomIndex + 1) % matchableCharactersCount;
            uint256 candidateID = matchableCharacters.at(index);

            if (candidateID == characterID) {
                if (matchableCharactersCount == 1) {
                    break;
                }
                if (matchableCharacters.at(matchableCharactersCount - 1) == candidateID) {
                    candidateID = matchableCharacters.at(0);
                } else {
                    candidateID = matchableCharacters.at(index + 1);
                }
            }
            if (
                characters.ownerOf(candidateID) ==
                characters.ownerOf(characterID)
            ) {
                continue;
            }

            foundOpponent = true;
            opponentID = candidateID;
            break;
        }

        require(foundOpponent, "No enemy found");

        matchByFinder[characterID] = Match(
            characterID,
            opponentID,
            block.timestamp
        );
        _matchableCharactersByTier[tier].remove(characterID);
        _matchableCharactersByTier[tier].remove(opponentID);
    }

    /// @dev increases a player's withdrawable funds depending on their position in the ranked leaderboard
    function _assignRewards(
        uint256 characterID,
        uint8 position,
        uint256 pool
    ) private {
        uint256 percentage = prizePercentages[position];
        uint256 amountToTransfer = (pool.mul(percentage)).div(100);
        address playerToTransfer = characters.ownerOf(characterID);

        _rankingRewardsByPlayer[playerToTransfer] = _rankingRewardsByPlayer[
            playerToTransfer
        ].add(amountToTransfer);
    }

    /// @dev removes a character from arena and clears it's matches
    function _removeCharacterFromArena(uint256 characterID)
        private
        characterInArena(characterID)
    {
        require(!isDefending[characterID], "Defender duel in process");

        Fighter storage fighter = fighterByCharacter[characterID];

        uint256 weaponID = fighter.weaponID;
        uint256 shieldID = fighter.shieldID;

        excessWagerByCharacter[characterID] = fighter.wager;

        // Shield removed first before the fighter is deleted
        if (fighter.useShield) {
            _isShieldInArena[shieldID] = false;
            shields.setNftVar(shieldID, 1, 0);
        }

        delete fighterByCharacter[characterID];
        delete matchByFinder[characterID];

        if (_duelQueue.contains(characterID)) {
            _duelQueue.remove(characterID);
        }

        uint8 tier = getArenaTier(characterID);

        if (_matchableCharactersByTier[tier].contains(characterID)) {
            _matchableCharactersByTier[tier].remove(characterID);
        }

        _isCharacterInArena[characterID] = false;
        _isWeaponInArena[weaponID] = false;

        // setting characters, weapons and shield NFTVAR_BUSY to 0
        characters.setNftVar(characterID, 1, 0);
        weapons.setNftVar(weaponID, 1, 0);
    }

    function fillGameCoffers() public restricted {
        skillToken.safeTransfer(address(game), gameCofferTaxDue);
        game.trackIncome(gameCofferTaxDue);
        gameCofferTaxDue = 0;
    }

    function setBaseWagerInCents(uint256 cents) external restricted {
        _baseWagerUSD  = ABDKMath64x64.divu(cents, 100);
    }

    function setTierWagerInCents(uint256 cents) external restricted {
        _tierWagerUSD = ABDKMath64x64.divu(cents, 100);
    }

    function setPrizePercentage(uint256 index, uint256 value) external restricted {
        prizePercentages[index] = value;
    }

    function setWageringFactor(uint8 factor) external restricted {
        wageringFactor = factor;
    }

    function setReRollFeePercent(uint256 percent) external restricted {
        reRollFeePercent = percent;
    }

    function setWithdrawFeePercent(uint256 percent) external restricted {
        withdrawFeePercent = percent;
    }

    function setRankingsPoolTaxPercent(uint8 percent) external restricted {
        _rankingsPoolTaxPercent = percent;
    }

    function setDecisionSeconds(uint256 secs) external restricted {
        decisionSeconds = secs;
    }

    function setWinningPoints(uint8 pts) external restricted {
        winningPoints = pts;
    }

    function setLosingPoints(uint8 pts) external restricted {
        losingPoints = pts;
    }

    function setMaxTopCharactersPerTier(uint8 max) external restricted {
        _maxTopCharactersPerTier = max;
    }

    function setSeasonDuration(uint256 duration) external restricted {
        seasonDuration = duration;
    }

    function setArenaAccess(uint256 accessFlags) external restricted {
        arenaAccess = accessFlags;
    }

    // Note: The following are debugging functions. Remove later.
    
    function clearDuelQueue() external restricted {
        uint256 length = _duelQueue.length();

        for (uint256 i = 0; i < length; i++) {
            if (matchByFinder[_duelQueue.at(i)].defenderID > 0) {
                isDefending[matchByFinder[_duelQueue.at(i)].defenderID] = false;
            }

            _duelQueue.remove(_duelQueue.at(i));
        }

        isDefending[0] = false;
    }

    function setRankingPoints(uint256 characterID, uint8 newRankingPoints)
        public
        restricted
    {
        rankingPointsByCharacter[characterID] = newRankingPoints;
    }
}