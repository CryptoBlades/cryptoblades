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
    /// @dev amount of points earned by winning a fight
    uint8 public winningPoints;
    /// @dev amount of points lost by losing fight
    uint8 public losingPoints;

    /// @dev Fighter by characterID
    mapping(uint256 => Fighter) public fighterByCharacter;
    /// @dev Active duel by characterID currently attacking
    mapping(uint256 => Duel) public duelByAttacker;
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
    /// @dev earnings earned by player
    mapping(address => uint256) private _rewardsByPlayer;
    /// @dev accumulated rewards per tier
    mapping(uint8 => uint256) private _rankingsPoolByTier;
    /// @dev duel earnings per character
    mapping(uint256 => uint256) private _duelEarningsByCharacter;
    /// @dev ranking by tier
    mapping(uint8 => uint256[4]) private _rankingByTier;
    /// @dev rankPoints by character
    mapping(uint256 => uint256) private _characterRankingPoints;
    /// @dev characters by ranking
    mapping(uint256 => uint256) private _charactersByRanking;

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
        _rankingsPoolTaxPercent = 15;
        unattackableSeconds = 2 minutes;
        decisionSeconds = 3 minutes;
        winningPoints = 5;
        losingPoints = 3;
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

        _fightersByTier[tier].add(characterID);
        _fightersByPlayer[msg.sender].add(characterID);
        fighterByCharacter[characterID] = Fighter(
            characterID,
            weaponID,
            shieldID,
            wager,
            useShield
        );
        // check if tiers are empty and update them if they are empty
        if (_charactersByRanking[tier] < _rankingByTier[tier].length) {
            _rankingByTier[tier][_charactersByRanking[tier]] = characterID;
        }
        _charactersByRanking[tier]++;
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

    /// @dev performs a given character's duel against its opponent
    function performDuel(uint256 attackerID)
        external
        isOwnedCharacter(attackerID)
    {
        require(hasPendingDuel(attackerID), "Character not in a duel");
        require(
            isAttackerWithinDecisionTime(attackerID),
            "Decision time expired"
        );

        uint256 defenderID = getOpponent(attackerID);
        uint8 defenderTrait = characters.getTrait(defenderID);
        uint8 attackerTrait = characters.getTrait(attackerID);

        uint24 attackerRoll = _getCharacterPowerRoll(attackerID, defenderTrait);
        uint24 defenderRoll = _getCharacterPowerRoll(defenderID, attackerTrait);

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
            memory bountyDistribution = _getDuelBountyDistribution(attackerID);

        _duelEarningsByCharacter[winnerID] = _duelEarningsByCharacter[winnerID]
            .add(bountyDistribution.winnerReward);
        fighterByCharacter[loserID].wager = fighterByCharacter[loserID]
            .wager
            .sub(bountyDistribution.loserPayment);

        if (fighterByCharacter[loserID].wager == 0) {
            _removeCharacterFromArena(loserID);
        }

        // add ranking points to the winner
        _characterRankingPoints[winnerID] = _characterRankingPoints[winnerID]
            .add(winningPoints);
        // subtract ranking points to the loser
        if (_characterRankingPoints[loserID] <= 3) {
            _characterRankingPoints[loserID] = 0;
        } else {
            _characterRankingPoints[loserID] = _characterRankingPoints[loserID]
                .sub(losingPoints);
        }
        //update winner
        processWinner(winnerID);
        //update loser
        processLoser(loserID);

        // add to the rankings pool
        _rankingsPoolByTier[getArenaTier(attackerID)] = _rankingsPoolByTier[
            getArenaTier(attackerID)
        ].add(bountyDistribution.rankingPoolTax);

        _updateLastActivityTimestamp(attackerID);
        _updateLastActivityTimestamp(defenderID);

        duelByAttacker[attackerID].isPending = false;
    }

    /// @dev withdraws a character and its items from the arena.
    /// if the character is in a battle, a penalty is charged
    function withdrawFromArena(uint256 characterID)
        external
        isOwnedCharacter(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];
        uint256 wager = fighter.wager;
        uint256 amountToTransfer = getUnclaimedDuelEarnings(characterID);

        if (hasPendingDuel(characterID)) {
            amountToTransfer = amountToTransfer.add(wager.sub(wager.div(4)));
        } else {
            amountToTransfer = amountToTransfer.add(wager);
        }

        // This also sets the character's earnings to 0
        _removeCharacterFromArena(characterID);

        skillToken.safeTransfer(msg.sender, amountToTransfer);
    }

    /// @dev withdraws a character's unclaimed duel earnings
    function withdrawDuelEarnings(uint256 characterID)
        external
        isOwnedCharacter(characterID)
    {
        uint256 amountToTransfer = getUnclaimedDuelEarnings(characterID);
        require(amountToTransfer > 0, "No unclaimed earnings");

        _duelEarningsByCharacter[characterID] = 0;

        skillToken.safeTransfer(msg.sender, amountToTransfer);
    }

    /// @dev withdraw all duel earnings
    function withdrawAllDuelEarnings() external {
        EnumerableSet.UintSet storage fighters = _fightersByPlayer[msg.sender];
        uint256 amountToTransfer;

        for (uint256 i = 0; i < fighters.length(); i++) {
            amountToTransfer = amountToTransfer.add(
                getUnclaimedDuelEarnings(fighters.at(i))
            );
            _duelEarningsByCharacter[fighters.at(i)] = 0;
        }

        require(amountToTransfer > 0, "No unclaimed earnings");

        skillToken.safeTransfer(msg.sender, amountToTransfer);
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

    /// @dev gets the character's unclaimed earnings
    function getUnclaimedDuelEarnings(uint256 characterID)
        public
        view
        returns (uint256)
    {
        return _duelEarningsByCharacter[characterID];
    }

    /// @dev gets the sum of all the sender's characters' unclaimed earnings
    function getAllUnclaimedDuelEarnings() external view returns (uint256) {
        EnumerableSet.UintSet storage playerFighters = _fightersByPlayer[
            msg.sender
        ];
        uint256 sum;

        for (uint256 i = 0; i < playerFighters.length(); i++) {
            sum = sum.add(_duelEarningsByCharacter[playerFighters.at(i)]);
        }

        return sum;
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

    ///@dev update the respective character's tier rank
    ///@dev function to update the winner player
    function processWinner(uint256 winnerID) internal {
        uint256 winnerPoints = _characterRankingPoints[winnerID];
        uint8 tier = getArenaTier(winnerID);
        uint256[4] storage winnerTier = _rankingByTier[tier];
        uint256 winnerPosition;
        bool winnerFound;

        // check if winner is withing the top 4
        for (uint8 i = 0; i < winnerTier.length; i++) {
            if (winnerID == winnerTier[i]) {
                winnerPosition = i;
                winnerFound = true;
                break;
            }
        }
        // if he is found, compare him to the lower index positions
        if (winnerFound) {
            winnerPosition = winnerPosition;
        }
        // else, compare it to the 4th one, if he is higher then replace the position and start the loop.
        else if (
            winnerPoints >=
            _characterRankingPoints[winnerTier[winnerTier.length - 1]]
        ) {
            winnerPosition = winnerTier[winnerTier.length - 1];
            winnerTier[winnerTier.length - 1] = winnerID;
        }
        for (uint256 i = winnerPosition; i >= 0; i--) {
            if (i <= 0) {
                break;
            }
            if (
                _characterRankingPoints[winnerTier[winnerPosition]] >=
                _characterRankingPoints[winnerTier[winnerPosition - 1]]
            ) {
                uint256 newPosition = winnerTier[winnerPosition - 1];
                winnerTier[winnerPosition - 1] = winnerTier[winnerPosition];
                winnerTier[winnerPosition] = newPosition;
                winnerPosition = winnerPosition - 1;
            } else {
                break;
            }
        }
    }

    function processLoser(uint256 loserID) internal {
        uint256 loserPoints = _characterRankingPoints[loserID];
        uint8 tier = getArenaTier(loserID);
        uint256[4] storage loserTier = _rankingByTier[tier];
        uint256 loserPosition;
        bool loserFound;
        for (uint8 i = 0; i < loserTier.length; i++) {
            if (loserID == loserTier[i]) {
                loserPosition = i;
                loserFound = true;
                break;
            }
        }

        if (loserFound) {
            for (uint256 i = loserPosition; i <= loserTier.length - 1; i++) {
                if (i >= loserTier.length - 1) {
                    break;
                }
                if (
                    _characterRankingPoints[loserTier[loserPosition]] <=
                    _characterRankingPoints[loserTier[loserPosition + 1]]
                ) {
                    uint256 newPosition = loserTier[loserPosition + 1];
                    loserTier[loserPosition + 1] = loserTier[loserPosition];
                    loserTier[loserPosition] = newPosition;
                    loserPosition = loserPosition + 1;
                } else {
                    break;
                }
            }
        }
    }

    /// @dev get the top players of a tier
    function getTopTierPlayers(uint256 characterID)
        public
        view
        returns (uint256[4] memory)
    {
        uint8 tier = getArenaTier(characterID);
        return _rankingByTier[tier];
    }

    /// @dev get the player's ranking points
    function getCharacterRankingPoints(uint256 characterID)
        public
        view
        returns (uint256)
    {
        return _characterRankingPoints[characterID];
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
        return fighterByCharacter[characterID].wager;
    }

    /// @dev wether or not the character is still in time to start a duel
    function isAttackerWithinDecisionTime(uint256 characterID)
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

    /// @dev function where admins can seta character's ranking points
    function setRankingPoints(uint256 characterID, uint8 newRankingPoints)
        public
    {
        _characterRankingPoints[characterID] = newRankingPoints;
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
        uint256 seed = randoms.getRandomSeed(msg.sender);

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

        delete fighterByCharacter[characterID];
        delete duelByAttacker[characterID];

        _fightersByPlayer[msg.sender].remove(characterID);

        uint8 tier = getArenaTier(characterID);

        _fightersByTier[tier].remove(characterID);

        _charactersInArena[characterID] = false;
        _weaponsInArena[weaponID] = false;
        _shieldsInArena[shieldID] = false;
        _duelEarningsByCharacter[characterID] = 0;
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
}
