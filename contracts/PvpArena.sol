pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "hardhat/console.sol";
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
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Fighter {
        uint256 characterID;
        uint256 weaponID;
        uint256 shieldID;
        /// @dev amount of skill wagered for this character
        uint256 wager;
        bool useShield;
    }
    struct Duel {
        uint256 attackerID;
        uint256 defenderID;
        uint256 createdAt;
        bool isPending;
    }

    struct BountyDistribution {
        uint256 winnerReward;
        uint256 loserPayment;
        uint256 rankingPoolTax;
    }

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    Shields public shields;
    IERC20 public skillToken;
    Raid1 public raids;
    IRandoms public randoms;

    /// @dev how much of a duel's bounty is sent to the rankings pool
    uint8 private _rankingsPoolTaxPercent;
    /// @dev how many times the cost of battling must be wagered to enter the arena
    uint8 public wageringFactor;
    /// @dev the base amount wagered per duel in dollars
    int128 private _baseWagerUSD;
    /// @dev how much extra USD is wagered per level tier
    int128 private _tierWagerUSD;
    /// @dev amount of time a character is unattackable
    uint256 public unattackableSeconds;
    /// @dev amount of time an attacker has to make a decision
    uint256 public decisionSeconds;
    /// @dev amount of points earned by winning a duel
    uint8 public winningPoints;
    /// @dev amount of points subtracted by losing duel
    uint8 public losingPoints;
    /// @dev amount of players that are considered for the top ranking
    uint8 private _maxCharactersPerRanking;

    /// @dev percentages of ranked prize distribution by fighter rank (represented as index)
    uint256[] public prizePercentages;
    /// @dev characters by id that are on queue to perform a duel
    EnumerableSet.UintSet private _duelQueue;

    /// @dev Fighter by characterID
    mapping(uint256 => Fighter) public fighterByCharacter;
    /// @dev Active duel by characterID currently attacking
    mapping(uint256 => Duel) public duelByAttacker;
    /// @dev ranking points by character
    mapping(uint256 => uint256) public characterRankingPoints;
    /// @dev excess wager by character for when they re-enter the arena
    mapping(uint256 => uint256) public excessWagerByCharacter;
    /// @dev funds available for withdrawal by address
    mapping(address => uint256) private _rankingEarningsByPlayer;
    /// @dev last time a character was involved in activity that makes it untattackable
    mapping(uint256 => uint256) private _lastActivityByCharacter;
    /// @dev IDs of characters available by tier (1-10, 11-20, etc...)
    mapping(uint8 => EnumerableSet.UintSet) private _fightersByTier;
    /// @dev IDs of characters in the arena per player
    mapping(address => EnumerableSet.UintSet) private _fightersByPlayer;
    /// @dev characters currently in the arena
    mapping(uint256 => bool) private _charactersInArena;
    /// @dev weapons currently in the arena
    mapping(uint256 => bool) private _weaponsInArena;
    /// @dev shields currently in the arena
    mapping(uint256 => bool) private _shieldsInArena;
    /// @dev accumulated rewards per tier
    mapping(uint8 => uint256) private _rankingsPoolByTier;
    /// @dev ranking by tier
    mapping(uint8 => uint256[]) private _rankingByTier;

    /// @dev total ranking points to use for larger seasons
    mapping(uint256 => uint256) public characterSeasonalRankingPoints;

    event NewDuel(
        uint256 indexed attacker,
        uint256 indexed defender,
        uint256 timestamp
    );
    event DuelFinished(
        uint256 indexed attacker,
        uint256 indexed defender,
        uint256 timestamp,
        uint256 attackerRoll,
        uint256 defenderRoll,
        bool attackerWon
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

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier enteringArenaChecks(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) {
        require(!_weaponsInArena[weaponID], "Weapon already in arena");
        require(
            characters.ownerOf(characterID) == msg.sender,
            "Not character owner"
        );
        require(weapons.ownerOf(weaponID) == msg.sender, "Not weapon owner");
        require(!raids.isCharacterRaiding(characterID), "Character is in raid");
        require(!raids.isWeaponRaiding(weaponID), "Weapon is in raid");
        require(characters.getNftVar(characterID, 1) == 0, "Character is busy");
        if (useShield) {
            require(
                shields.ownerOf(shieldID) == msg.sender,
                "Not shield owner"
            );
            require(shields.getNftVar(shieldID, 1) == 0, "Shield is busy");
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
        _rankingsPoolTaxPercent = 15;
        unattackableSeconds = 2 minutes;
        decisionSeconds = 3 minutes;
        winningPoints = 5;
        losingPoints = 3;
        _maxCharactersPerRanking = 4;
        prizePercentages.push(60);
        prizePercentages.push(30);
        prizePercentages.push(10);
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
        if (useShield) shields.setNftVar(shieldID, 1, 1);

        _fightersByTier[tier].add(characterID);
        _fightersByPlayer[msg.sender].add(characterID);
        fighterByCharacter[characterID] = Fighter(
            characterID,
            weaponID,
            shieldID,
            wager.add(getCharacterWager(characterID)),
            useShield
        );

        excessWagerByCharacter[characterID] = 0;

        // add the character into the tier's ranking if it is not full yet
        uint256 fightersAmount = _fightersByTier[tier].length();
        if (fightersAmount <= _maxCharactersPerRanking) {
            _rankingByTier[tier].push(characterID);
        }
        // character starts unattackable
        _updateLastActivityTimestamp(characterID);

        skillToken.transferFrom(msg.sender, address(this), wager);
        // set the character as BUSY setting NFTVAR_BUSY to 1
        characters.setNftVar(characterID, 1, 1);
        weapons.setNftVar(weaponID, 1, 1);
    }

    /// @dev attempts to find an opponent for a character
    function requestOpponent(uint256 characterID)
        external
        characterInArena(characterID)
        isOwnedCharacter(characterID)
    {
        require(!hasPendingDuel(characterID), "Opponent already requested");
        _assignOpponent(characterID);
    }

    /// @dev requests a new opponent for a fee
    function reRollOpponent(uint256 characterID)
        external
        characterInArena(characterID)
        isOwnedCharacter(characterID)
    {
        require(hasPendingDuel(characterID), "Character is not dueling");

        _assignOpponent(characterID);

        skillToken.transferFrom(
            msg.sender,
            address(this),
            getDuelCost(characterID).div(4)
        );
    }

    /// @dev adds a character to the duel queue
    function preparePerformDuel(uint256 attackerID)
        external
        isOwnedCharacter(attackerID)
    {
        require(hasPendingDuel(attackerID), "Character not in a duel");
        require(
            isCharacterWithinDecisionTime(attackerID),
            "Decision time expired"
        );

        require(
            !_duelQueue.contains(attackerID),
            "Character is already in duel queue"
        );

        _duelQueue.add(attackerID);
    }

    /// @dev performs all queued duels
    function performDuels(uint256[] calldata attackerIDs) external restricted {
        for (uint256 i = 0; i < attackerIDs.length; i++) {
            uint256 attackerID = _duelQueue.at(i);
            uint256 defenderID = getOpponent(attackerID);
            uint8 defenderTrait = characters.getTrait(defenderID);
            uint8 attackerTrait = characters.getTrait(attackerID);

            uint24 attackerRoll = _getCharacterPowerRoll(
                attackerID,
                defenderTrait
            );
            uint24 defenderRoll = _getCharacterPowerRoll(
                defenderID,
                attackerTrait
            );

            uint256 winnerID = attackerRoll >= defenderRoll
                ? attackerID
                : defenderID;
            uint256 loserID = attackerRoll >= defenderRoll
                ? defenderID
                : attackerID;

            emit DuelFinished(
                attackerID,
                defenderID,
                block.timestamp,
                attackerRoll,
                defenderRoll,
                attackerRoll >= defenderRoll
            );

            BountyDistribution
                memory bountyDistribution = _getDuelBountyDistribution(
                    attackerID
                );

            fighterByCharacter[winnerID].wager = fighterByCharacter[winnerID]
                .wager
                .add(bountyDistribution.winnerReward);
            fighterByCharacter[loserID].wager = fighterByCharacter[loserID]
                .wager
                .sub(bountyDistribution.loserPayment);

            if (
                fighterByCharacter[loserID].wager < getDuelCost(loserID) ||
                fighterByCharacter[loserID].wager <
                getEntryWager(loserID).div(4)
            ) {
                _removeCharacterFromArena(loserID);
            }

            // add ranking points and seasonal ranking points to the winner
            characterRankingPoints[winnerID] = characterRankingPoints[winnerID]
                .add(winningPoints);
            characterSeasonalRankingPoints[
                winnerID
            ] = characterSeasonalRankingPoints[winnerID].add(winningPoints);
            // check if the loser's current raking points are 3 or less and set them to 0 if that's the case, else subtract the ranking points
            if (characterRankingPoints[loserID] <= 3) {
                characterRankingPoints[loserID] = 0;
            } else {
                characterRankingPoints[loserID] = characterRankingPoints[
                    loserID
                ].sub(losingPoints);
            }
            // do the same process with seasonal rankingpoints
            if (characterSeasonalRankingPoints[loserID] <= 3) {
                characterSeasonalRankingPoints[loserID] = 0;
            } else {
                characterSeasonalRankingPoints[
                    loserID
                ] = characterSeasonalRankingPoints[loserID].sub(losingPoints);
            }
            processWinner(winnerID);
            processLoser(loserID);

            // add to the rankings pool
            _rankingsPoolByTier[getArenaTier(attackerID)] = _rankingsPoolByTier[
                getArenaTier(attackerID)
            ].add(bountyDistribution.rankingPoolTax);

            _updateLastActivityTimestamp(attackerID);
            _updateLastActivityTimestamp(defenderID);

            duelByAttacker[attackerID].isPending = false;

            _duelQueue.remove(attackerID);
        }
    }

    /// @dev withdraws a character and its items from the arena.
    /// if the character is in a battle, a penalty is charged
    function withdrawFromArena(uint256 characterID)
        external
        isOwnedCharacter(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];
        uint256 wager = fighter.wager;
        uint256 entryWager = getEntryWager(characterID);

        if (hasPendingDuel(characterID)) {
            wager = wager.sub(entryWager.div(4));
        }

        _removeCharacterFromArena(characterID);

        excessWagerByCharacter[characterID] = 0;
        fighter.wager = 0;

        skillToken.safeTransfer(msg.sender, wager);
    }

    /// @dev returns the SKILL amounts distributed to the winner and the ranking pool
    function _getDuelBountyDistribution(uint256 attackerID)
        private
        view
        returns (BountyDistribution memory bountyDistribution)
    {
        uint256 duelCost = getDuelCost(attackerID);
        uint256 bounty = duelCost.mul(2);
        uint256 poolTax = _rankingsPoolTaxPercent.mul(bounty).div(100);

        uint256 reward = bounty.sub(poolTax).sub(duelCost);

        return BountyDistribution(reward, duelCost, poolTax);
    }

    function getRankingRewardsPool(uint8 tier) public view returns (uint256) {
        return _rankingsPoolByTier[tier];
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
        uint256 length = _fightersByPlayer[msg.sender].length();
        uint256[] memory values = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = _fightersByPlayer[msg.sender].at(i);
        }

        return values;
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

    /// @dev updates the rank of the winner of a duel
    function processWinner(uint256 winnerID) private {
        uint256 rankingPoints = characterRankingPoints[winnerID];
        uint8 tier = getArenaTier(winnerID);
        uint256[] storage ranking = _rankingByTier[tier];
        uint256 winnerPosition;
        bool winnerInRanking;

        // check if winner is withing the top 4
        for (uint8 i = 0; i < ranking.length; i++) {
            if (winnerID == ranking[i]) {
                winnerPosition = i;
                winnerInRanking = true;
                break;
            }
        }
        // if the winner is not in the top characters we then compare it to the last character of the top rank, swapping positions if the condition is met
        if (
            !winnerInRanking &&
            rankingPoints >=
            getCharacterRankingPoints(ranking[ranking.length - 1])
        ) {
            ranking[ranking.length - 1] = winnerID;
            winnerPosition = ranking.length - 1;
        }

        for (winnerPosition; winnerPosition > 0; winnerPosition--) {
            if (
                getCharacterRankingPoints(ranking[winnerPosition]) >=
                getCharacterRankingPoints(ranking[winnerPosition - 1])
            ) {
                uint256 oldCharacter = ranking[winnerPosition - 1];
                ranking[winnerPosition - 1] = winnerID;
                ranking[winnerPosition] = oldCharacter;
            } else {
                break;
            }
        }
    }

    /// @dev updates the rank of the loser of a duel
    function processLoser(uint256 loserID) private {
        uint256 rankingPoints = characterRankingPoints[loserID];
        uint8 tier = getArenaTier(loserID);
        uint256[] storage ranking = _rankingByTier[tier];
        uint256 loserPosition;
        bool loserFound;

        // check if the loser is in the top 4
        for (uint8 i = 0; i < ranking.length; i++) {
            if (loserID == ranking[i]) {
                loserPosition = i;
                loserFound = true;
                break;
            }
        }
        // if the character is within the top 4, compare it to the character that precedes it and swap positions if the condition is met
        if (loserFound) {
            for (
                loserPosition;
                loserPosition < ranking.length - 1;
                loserPosition++
            ) {
                if (
                    rankingPoints <
                    getCharacterRankingPoints(ranking[loserPosition + 1])
                ) {
                    uint256 oldCharacter = ranking[loserPosition + 1];
                    ranking[loserPosition + 1] = loserID;
                    ranking[loserPosition] = oldCharacter;
                } else {
                    break;
                }
            }
        }
    }

    /// @dev get the top ranked characters of a tier
    function getTierTopRankers(uint256 characterID)
        public
        view
        returns (uint256[] memory)
    {
        uint8 tier = getArenaTier(characterID);
        uint256 arrayLength;
        // we return only the top 3 players, returning the array without the pivot ranker if he exists
        if (_rankingByTier[tier].length == _maxCharactersPerRanking) {
            arrayLength = _rankingByTier[tier].length - 1;
        } else {
            arrayLength = _rankingByTier[tier].length;
        }
        uint256[] memory topRankers = new uint256[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            topRankers[i] = _rankingByTier[tier][i];
        }

        return topRankers;
    }

    /// @dev get the character's ranking points
    function getCharacterRankingPoints(uint256 characterID)
        public
        view
        returns (uint256)
    {
        return characterRankingPoints[characterID];
    }

    /// @dev get the character's seasonal points
    function getCharacterSeasonalRankingPoints(uint256 characterID)
        public
        view
        returns (uint256)
    {
        return characterSeasonalRankingPoints[characterID];
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

    /// @dev get an attacker's opponent
    function getOpponent(uint256 characterID) public view returns (uint256) {
        require(hasPendingDuel(characterID), "Character has no pending duel");
        return duelByAttacker[characterID].defenderID;
    }

    /// @dev get amount wagered for a given character
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

    /// @dev wether or not the character is still in time to start a duel
    function isCharacterWithinDecisionTime(uint256 characterID)
        public
        view
        returns (bool)
    {
        return
            duelByAttacker[characterID].createdAt.add(decisionSeconds) >
            block.timestamp;
    }

    /// @dev wether or not the character is the attacker in a duel
    // and has not performed an action
    function hasPendingDuel(uint256 characterID) public view returns (bool) {
        return duelByAttacker[characterID].isPending;
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

    /// @dev function where admins can set a character's ranking points
    function setRankingPoints(uint256 characterID, uint8 newRankingPoints)
        public
        restricted
    {
        characterRankingPoints[characterID] = newRankingPoints;
    }

    function _getCharacterPowerRoll(uint256 characterID, uint8 opponentTrait)
        private
        view
        returns (uint24)
    {
        // TODO:
        // - [ ] consider shield
        uint8 trait = characters.getTrait(characterID);
        uint24 basePower = characters.getPower(characterID);
        uint256 weaponID = fighterByCharacter[characterID].weaponID;
        uint256 seed = randoms.getRandomSeedUsingHash(
            msg.sender,
            blockhash(block.number)
        );

        (
            ,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait
        ) = weapons.getFightData(weaponID, trait);

        int128 playerTraitBonus = getPVPTraitBonusAgainst(
            trait,
            weaponTrait,
            opponentTrait
        );

        uint256 playerFightPower = game.getPlayerPower(
            basePower,
            weaponMultFight,
            weaponBonusPower
        );

        uint256 playerPower = RandomUtil.plusMinus10PercentSeeded(
            playerFightPower,
            seed
        );

        return uint24(playerTraitBonus.mulu(playerPower));
    }

    /// @dev returns the trait bonuses against another character
    function getPVPTraitBonusAgainst(
        uint8 characterTrait,
        uint8 weaponTrait,
        uint8 opponentTrait
    ) public view returns (int128) {
        int128 traitBonus = ABDKMath64x64.fromUInt(1);
        int128 fightTraitBonus = game.fightTraitBonus();
        int128 charTraitFactor = ABDKMath64x64.divu(50, 100);

        if (characterTrait == weaponTrait) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }

        // We apply 50% of char trait bonuses because they are applied twice (once per fighter)
        if (game.isTraitEffectiveAgainst(characterTrait, opponentTrait)) {
            traitBonus = traitBonus.add(fightTraitBonus.mul(charTraitFactor));
        } else if (
            game.isTraitEffectiveAgainst(opponentTrait, characterTrait)
        ) {
            traitBonus = traitBonus.sub(fightTraitBonus.mul(charTraitFactor));
        }

        return traitBonus;
    }

    /// @dev removes a character from the arena's state
    function _removeCharacterFromArena(uint256 characterID) private {
        require(isCharacterInArena(characterID), "Character not in arena");
        Fighter storage fighter = fighterByCharacter[characterID];

        uint256 weaponID = fighter.weaponID;
        uint256 shieldID = fighter.shieldID;

        excessWagerByCharacter[characterID] = fighter.wager;

        delete fighterByCharacter[characterID];
        delete duelByAttacker[characterID];

        _fightersByPlayer[msg.sender].remove(characterID);

        uint8 tier = getArenaTier(characterID);

        _fightersByTier[tier].remove(characterID);

        _charactersInArena[characterID] = false;
        _weaponsInArena[weaponID] = false;
        _shieldsInArena[shieldID] = false;
        // setting characters, weapons and shield NFTVAR_BUSY to 0
        characters.setNftVar(characterID, 1, 0);
        weapons.setNftVar(weaponID, 1, 0);
        shields.setNftVar(shieldID, 1, 0);
    }

    /// @dev attempts to find an opponent for a character.
    function _assignOpponent(uint256 characterID) private {
        uint8 tier = getArenaTier(characterID);

        EnumerableSet.UintSet storage fightersInTier = _fightersByTier[tier];

        require(fightersInTier.length() != 0, "No opponents available in tier");

        uint256 seed = randoms.getRandomSeed(msg.sender);
        uint256 randomIndex = RandomUtil.randomSeededMinMax(
            0,
            fightersInTier.length() - 1,
            seed
        );

        uint256 opponentID;
        bool foundOpponent = false;
        uint256 fighterCount = fightersInTier.length();

        // run through fighters from a random starting point until we find one or none are available
        for (uint256 i = 0; i < fighterCount; i++) {
            uint256 index = (randomIndex + i) % fighterCount;
            uint256 candidateID = fightersInTier.at(index);

            if (candidateID == characterID) continue;
            if (!isCharacterAttackable(candidateID)) continue;
            if (
                characters.ownerOf(candidateID) ==
                characters.ownerOf(characterID)
            ) continue;

            foundOpponent = true;
            opponentID = candidateID;
            break;
        }

        require(foundOpponent, "No opponent found");

        duelByAttacker[characterID] = Duel(
            characterID,
            opponentID,
            block.timestamp,
            true
        );

        // mark both characters as unattackable
        _lastActivityByCharacter[characterID] = block.timestamp;
        _lastActivityByCharacter[opponentID] = block.timestamp;

        emit NewDuel(characterID, opponentID, block.timestamp);
    }

    /// @dev returns the senders fighters in the arena
    function _getMyFighters() internal view returns (Fighter[] memory) {
        uint256[] memory characterIDs = getMyParticipatingCharacters();
        Fighter[] memory fighters = new Fighter[](characterIDs.length);

        for (uint256 i = 0; i < characterIDs.length; i++) {
            fighters[i] = fighterByCharacter[characterIDs[i]];
        }

        return fighters;
    }

    /// @dev set the ranking points of a player to 0 and update the rank,
    function _resetCharacterRankingPoints(uint256 characterID) public {
        //TODO Determine if this is the right approach as it might less efficient gas wise
        characterRankingPoints[characterID] = 0;
        processLoser(characterID);
    }

    /// @dev assigns the ranking rewards pool to top players
    function assignRankedRewards() external restricted {
        // Note: Loops over 15 tiers. Should not be reachable anytime in the foreseeable future.
        for (uint8 i = 0; i <= 15; i++) {
            if (_fightersByTier[i].length() == 0) {
                continue;
            }

            uint256 difference;

            if (_rankingByTier[i].length <= prizePercentages.length) {
                difference = prizePercentages.length - _rankingByTier[i].length;
            } else {
                difference = 0;
            }

            // Note: If there are less players than top positions, excess is transferred to top 1.
            if (_rankingByTier[i].length < prizePercentages.length) {
                uint256 excessPercentage;
                address topOnePlayer = characters.ownerOf(_rankingByTier[i][0]);

                // Note: We accumulate excess percentage.
                for (
                    uint256 j = prizePercentages.length - difference;
                    j < prizePercentages.length;
                    j++
                ) {
                    excessPercentage = excessPercentage.add(
                        prizePercentages[j]
                    );
                }

                // Note: We assign excessive rewards to top 1 player.
                _rankingEarningsByPlayer[
                    topOnePlayer
                ] = _rankingEarningsByPlayer[topOnePlayer].add(
                    (_rankingsPoolByTier[i].mul(excessPercentage)).div(100)
                );
            }

            // Note: We assign rewards normally to all possible players.
            for (uint8 h = 0; h < prizePercentages.length - difference; h++) {
                _assignRewards(_rankingByTier[i][h], h, _rankingsPoolByTier[i]);
            }

            // Note: We reset ranking prize pools.
            _rankingsPoolByTier[i] = 0;
        }
    }

    /// @dev increases a players withdrawable funds depending on their position in the ranked leaderboard
    function _assignRewards(
        uint256 characterID,
        uint8 position,
        uint256 pool
    ) private {
        uint256 percentage = prizePercentages[position];
        uint256 amountToTransfer = (pool.mul(percentage)).div(100);
        address playerToTransfer = characters.ownerOf(characterID);

        _rankingEarningsByPlayer[playerToTransfer] = _rankingEarningsByPlayer[
            playerToTransfer
        ].add(amountToTransfer);
    }

    /// @dev allows a player to withdraw their ranking earnings
    function withdrawRankedRewards() external {
        uint256 amountToTransfer = _rankingEarningsByPlayer[msg.sender];

        if (amountToTransfer > 0) {
            _rankingEarningsByPlayer[msg.sender] = 0;

            skillToken.safeTransfer(msg.sender, amountToTransfer);
        }
    }

    /// @dev returns ranked prize percentages distribution
    function getPrizePercentages() external view returns (uint256[] memory) {
        return prizePercentages;
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
}
