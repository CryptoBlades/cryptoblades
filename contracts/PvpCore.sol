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
import "./common.sol";
import "./PvpRankings.sol";

contract PvpCore is Initializable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint8;
    using SafeMath for uint24;
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

    struct Duelist {
        uint256 ID;
        uint8 level;
        uint8 trait;
        uint24 roll;
        uint256 power;
    }

    struct Duel {
        Duelist attacker;
        Duelist defender;
        uint8 tier;
        uint256 cost;
        bool attackerWon;
        uint256 bonusRank;
    }

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    Shields public shields;
    IERC20 public skillToken;
    IRandoms public randoms;
    PvpRankings public pvprankings;

    /// @dev the base amount wagered per duel in dollars
    int128 private _baseWagerUSD;
    /// @dev how much extra USD is wagered per level tier
    int128 private _tierWagerUSD;
    /// @dev how many times the cost of battling must be wagered to enter the arena
    uint8 public wageringFactor;
    /// @dev percentage of duel cost charged when rerolling opponent
    uint256 public reRollFeePercent;
    /// @dev percentage of entry wager charged when withdrawing from arena with pending duel
    uint256 public withdrawFeePercent;
    /// @dev amount of time a match finder has to make a decision
    uint256 public decisionSeconds;
    /// @dev allows or blocks entering arena (we can extend later to disable other parts such as rerolls)
    uint256 public arenaAccess; // 0 = cannot join, 1 = can join
    /// @dev value sent by players to offset bot's duel costs
    uint256 public duelOffsetCost;
    /// @dev PvP bot address
    address payable public pvpBotAddress;
    /// @dev characters by id that are on queue to perform a duel
    EnumerableSet.UintSet private _duelQueue;

    /// @dev Fighter by characterID
    mapping(uint256 => Fighter) public fighterByCharacter;
    /// @dev Active match by characterID of the finder
    mapping(uint256 => Match) public matchByFinder;
    /// @dev if character is currently in the arena
    mapping(uint256 => bool) public isCharacterInArena;
    /// @dev if weapon is currently in the arena
    mapping(uint256 => bool) public isWeaponInArena;
    /// @dev if shield is currently in the arena
    mapping(uint256 => bool) public isShieldInArena;
    /// @dev if defender is in a duel that has not finished processing
    mapping(uint256 => bool) public isDefending;
    /// @dev if a character is someone else's opponent
    mapping(uint256 => uint256) public finderByOpponent;
    /// @dev character's tier when it last entered arena. Used to reset rank if it changes
    mapping(uint256 => uint8) public previousTierByCharacter;
    /// @dev excess wager by character for when they re-enter the arena
    mapping(uint256 => uint256) public excessWagerByCharacter;
    /// @dev IDs of characters available for matchmaking by tier
    mapping(uint8 => EnumerableSet.UintSet) private _matchableCharactersByTier;
    /// @dev special weapon reroll timestamp
    mapping(uint256 => uint256) public specialWeaponRerollTimestamp;
    /// @dev owner's address by character ID
    mapping(uint256 => address) private _ownerByCharacter;
    
    event DuelFinished(
        uint256 indexed attacker,
        uint256 indexed defender,
        uint256 timestamp,
        uint256 attackerRoll,
        uint256 defenderRoll,
        bool attackerWon,
        uint256 bonusRank
    );

    event CharacterKicked(
        uint256 indexed characterID,
        uint256 kickedBy,
        uint256 timestamp
    );

    modifier characterInArena(uint256 characterID) {
        _characterInArena(characterID);
        _;
    }

    function _characterInArena(uint256 characterID) internal view {
        require(isCharacterInArena[characterID], "N");
    }

    modifier characterWithinDecisionTime(uint256 characterID) {
        _characterWithinDecisionTime(characterID);
        _;
    }

    function _characterWithinDecisionTime(uint256 characterID) internal view {
        require(
            isCharacterWithinDecisionTime(characterID),
            "D"
        );
    }

    modifier characterNotUnderAttack(uint256 characterID) {
        _characterNotUnderAttack(characterID);
        _;
    }

    function _characterNotUnderAttack(uint256 characterID) internal view {
        require(!isCharacterUnderAttack(characterID), "U");
    }

    modifier characterNotInDuel(uint256 characterID) {
        _characterNotInDuel(characterID);
        _;
    }

    function _characterNotInDuel(uint256 characterID) internal view {
        require(!isCharacterInDuel(characterID), "Q");
    }

    modifier isOwnedCharacter(uint256 characterID) {
        require(_ownerByCharacter[characterID] == msg.sender);
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender));
    }

    function initialize(
        address gameContract,
        address shieldsContract,
        address randomsContract,
        address pvpRankingsContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        shields = Shields(shieldsContract);
        skillToken = IERC20(game.skillToken());
        randoms = IRandoms(randomsContract);
        pvprankings = PvpRankings(pvpRankingsContract);

        // TODO: Tweak these values
        _baseWagerUSD = ABDKMath64x64.divu(500, 100); // $5
        _tierWagerUSD = ABDKMath64x64.divu(50, 100); // $0.5
        wageringFactor = 3;
        reRollFeePercent = 25;
        withdrawFeePercent = 25;
        decisionSeconds = 2 minutes;
        duelOffsetCost = 0.005 ether;
    }

    /// @dev enter the arena with a character, a weapon and optionally a shield
    function enterArena(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield,
        bool tierless
    ) external {
        require(
            characters.ownerOf(characterID) == msg.sender &&
                weapons.ownerOf(weaponID) == msg.sender
        );

        require(characters.getNftVar(characterID, 1) == 0 && weapons.getNftVar(weaponID, 1) == 0, "B");

        if (useShield) {
            require(shields.ownerOf(shieldID) == msg.sender);
            require(shields.getNftVar(shieldID, 1) == 0, "S");
        }

        require((arenaAccess & 1) == 1, "L");

        uint8 tier;
        if (tierless) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        uint256 wager = getEntryWagerByTier(tier);

        if (_ownerByCharacter[characterID] != msg.sender) {
            _ownerByCharacter[characterID] = msg.sender;
        }

        if (previousTierByCharacter[characterID] != tier) {
            pvprankings.changeRankingPoints(characterID, 0);
        }

        pvprankings.handleEnterArena(characterID, tier);

        isCharacterInArena[characterID] = true;
        characters.setNftVar(characterID, 1, 1);

        isWeaponInArena[weaponID] = true;
        weapons.setNftVar(weaponID, 1, 1);

        if (useShield) {
            isShieldInArena[shieldID] = true;
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
        previousTierByCharacter[characterID] = tier;
        excessWagerByCharacter[characterID] = 0;

        skillToken.transferFrom(msg.sender, address(this), wager);
    }

    /// @dev withdraws a character and its items from the arena.
    /// if the character is in a battle, a penalty is charged
    function withdrawFromArena(uint256 characterID)
        external
        isOwnedCharacter(characterID)
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
        characterNotInDuel(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];
        uint256 wager = fighter.wager;

        uint8 tier;
        
        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        uint256 entryWager = getEntryWager(characterID);

        if (matchByFinder[characterID].createdAt != 0) {
            if (wager < entryWager.mul(withdrawFeePercent).div(100)) {
                wager = 0;
            } else {
                wager = wager.sub(entryWager.mul(withdrawFeePercent).div(100));
            }
        }

        _removeCharacterFromArena(characterID, tier);

        excessWagerByCharacter[characterID] = 0;
        fighter.wager = 0;

        skillToken.safeTransfer(msg.sender, wager);
    }

    /// @dev attempts to find an opponent for a character
    function findOpponent(uint256 characterID)
        external
        isOwnedCharacter(characterID)
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
        characterNotInDuel(characterID)
    {
        require(matchByFinder[characterID].createdAt == 0, "M");

        uint8 tier;

        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        _assignOpponent(characterID, tier);
    }

    /// @dev attempts to find a new opponent for a fee
    function reRollOpponent(uint256 characterID)
        external
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
        isOwnedCharacter(characterID)
        characterNotInDuel(characterID)
    {
        uint256 opponentID = getOpponent(characterID);
        uint8 tier;
        
        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        require(matchByFinder[characterID].createdAt != 0, "R");

        delete finderByOpponent[opponentID];
        if (isCharacterInArena[opponentID]) {
            _matchableCharactersByTier[tier].add(opponentID);
        }

        _assignOpponent(characterID, tier);

        uint256 weaponID = fighterByCharacter[characterID].weaponID;
        if(weapons.getWeaponType(weaponID) > 0 && specialWeaponRerollTimestamp[weaponID] < block.timestamp) {
            specialWeaponRerollTimestamp[weaponID] = block.timestamp + 24 hours;
        }
        else {
            skillToken.transferFrom(
                msg.sender,
                address(this),
                getDuelCostByTier(tier).mul(reRollFeePercent).div(100)
            );
        }
    }

    /// @dev adds a character to the duel queue
    function prepareDuel(uint256 attackerID)
        external
        payable
        isOwnedCharacter(attackerID)
        characterInArena(attackerID)
        characterWithinDecisionTime(attackerID)
        characterNotInDuel(attackerID)
    {
        require((arenaAccess & 1) == 1);
        require(msg.value == duelOffsetCost, "O");

        uint256 defenderID = getOpponent(attackerID);

        pvprankings.handlePrepareDuel(attackerID);

        pvprankings.handlePrepareDuel(defenderID);

        isDefending[defenderID] = true;

        _duelQueue.add(attackerID);

        pvpBotAddress.transfer(msg.value);
    }

    function createDuelist(uint256 id) internal view returns (Duelist memory duelist) {
        duelist.ID = id;

        (
            , // xp
            duelist.level,
            duelist.trait,
            , // staminaTimestamp
            , // head
            , // torso
            , // legs
            , // boots
            , // race
        ) = characters.get(id);
    }

    /// @dev performs a list of duels
    function performDuels(uint256[] calldata attackerIDs) external restricted {
        for (uint256 i = 0; i < attackerIDs.length; i++) {
            Duel memory duel;
            duel.attacker = createDuelist(attackerIDs[i]);

            if (!_duelQueue.contains(duel.attacker.ID)) continue;

            duel.defender = createDuelist(getOpponent(duel.attacker.ID));

            if (previousTierByCharacter[duel.attacker.ID] == 20) {
                duel.tier = 20;
            } else {
                duel.tier = getArenaTierForLevel(duel.attacker.level);
            }

            duel.cost = getDuelCostByTier(duel.tier);

            duel.attacker.power = getCharacterPower(duel.attacker.ID);
            duel.defender.power = getCharacterPower(duel.defender.ID);

            duel.attacker.roll = _getCharacterPowerRoll(duel.attacker, duel.defender.trait);
            duel.defender.roll = _getCharacterPowerRoll(duel.defender, duel.attacker.trait);

            // Reduce defender roll if attacker has a shield
            if (fighterByCharacter[duel.attacker.ID].useShield) {
                uint24 attackerShieldDefense = 3;

                uint8 attackerShieldTrait = shields.getTrait(
                    fighterByCharacter[duel.attacker.ID].shieldID
                );

                if (
                    Common.isTraitEffectiveAgainst(attackerShieldTrait, duel.defender.trait)
                ) {
                    attackerShieldDefense = 10;
                }

                duel.defender.roll = uint24(
                    (duel.defender.roll.mul(uint24(100).sub(attackerShieldDefense)))
                        .div(100)
                );
            }

            // Reduce attacker roll if defender has a shield
            if (fighterByCharacter[duel.defender.ID].useShield) {
                uint24 defenderShieldDefense = 3;

                uint8 defenderShieldTrait = shields.getTrait(
                    fighterByCharacter[duel.defender.ID].shieldID
                );

                if (
                    Common.isTraitEffectiveAgainst(defenderShieldTrait, duel.attacker.trait)
                ) {
                    defenderShieldDefense = 10;
                }

                duel.attacker.roll = uint24(
                    (duel.attacker.roll.mul(uint24(100).sub(defenderShieldDefense)))
                        .div(100)
                );
            }

            duel.attackerWon = (duel.attacker.roll >= duel.defender.roll);

            uint256 winnerID = duel.attackerWon
                ? duel.attacker.ID
                : duel.defender.ID;
            uint256 loserID = duel.attackerWon
                ? duel.defender.ID
                : duel.attacker.ID;

            if (winnerID == duel.attacker.ID && duel.attacker.power < duel.defender.power) {
                duel.bonusRank = Common.getBonusRankingPoints(duel.attacker.power, duel.defender.power);
            } else if (winnerID == duel.defender.ID && duel.attacker.power > duel.defender.power) {
                duel.bonusRank = Common.getBonusRankingPoints(duel.defender.power, duel.attacker.power);           
            }

            emit DuelFinished(
                duel.attacker.ID,
                duel.defender.ID,
                block.timestamp,
                duel.attacker.roll,
                duel.defender.roll,
                duel.attackerWon,
                duel.bonusRank
            );

            (
                uint256 reward,
                uint256 poolTax
            ) = pvprankings.getDuelBountyDistribution(duel.cost);

            fighterByCharacter[winnerID].wager = fighterByCharacter[winnerID]
                .wager
                .add(reward);

            uint256 loserWager;

            if (
                fighterByCharacter[loserID].wager <
                duel.cost
            ) {
                loserWager = 0;
            } else {
                loserWager = fighterByCharacter[loserID].wager.sub(
                    duel.cost
                );
            }

            fighterByCharacter[loserID].wager = loserWager;

            delete matchByFinder[duel.attacker.ID];
            delete finderByOpponent[duel.defender.ID];
            isDefending[duel.defender.ID] = false;

            if (
                fighterByCharacter[loserID].wager < duel.cost ||
                fighterByCharacter[loserID].wager <
                getEntryWagerByTier(duel.tier).mul(withdrawFeePercent).div(100)
            ) {
                _removeCharacterFromArena(loserID, duel.tier);
                emit CharacterKicked(
                    loserID,
                    winnerID,
                    block.timestamp
                );
            } else {
                _matchableCharactersByTier[duel.tier].add(loserID);
            }

            _matchableCharactersByTier[duel.tier].add(winnerID);

            pvprankings.handlePerformDuel(winnerID, loserID, duel.bonusRank, duel.tier, poolTax);

            skillToken.safeTransfer(address(pvprankings), poolTax);

            _duelQueue.remove(duel.attacker.ID);
        }
    }

    /// @dev wether or not the character is still in time to start a duel
    function isCharacterWithinDecisionTime(uint256 characterID)
        internal
        view
        returns (bool)
    {
        return
            matchByFinder[characterID].createdAt.add(decisionSeconds) >
            block.timestamp;
    }

    /// @dev checks wether or not the character is actively someone else's opponent
    function isCharacterUnderAttack(uint256 characterID)
        public
        view
        returns (bool)
    {
        if (finderByOpponent[characterID] == 0) {
            if (matchByFinder[0].defenderID == characterID) {
                return isCharacterWithinDecisionTime(0);
            }
            return false;
        }

        return isCharacterWithinDecisionTime(finderByOpponent[characterID]);
    }

    /// @dev checks wether or not the character is currently in the duel queue
    function isCharacterInDuel(uint256 characterID)
        internal
        view
        returns (bool)
    {
        return _duelQueue.contains(characterID) || isDefending[characterID];
    }

    /// @dev gets the amount of SKILL required to enter the arena
    function getEntryWager(uint256 characterID) public view returns (uint256) {
        return getDuelCost(characterID).mul(wageringFactor);
    }

    /// @dev gets the amount of SKILL required to enter the arena by tier
    function getEntryWagerByTier(uint8 tier) public view returns (uint256) {
        return getDuelCostByTier(tier).mul(wageringFactor);
    }

    /// @dev gets the amount of SKILL that is risked per duel
    function getDuelCost(uint256 characterID) public view returns (uint256) {
        if (previousTierByCharacter[characterID] == 20) {
            return  game.usdToSkill(_baseWagerUSD);
        }

        int128 tierExtra = ABDKMath64x64
            .divu(getArenaTier(characterID).mul(100), 100)
            .mul(_tierWagerUSD);

        return game.usdToSkill(_baseWagerUSD.add(tierExtra));
    }

    /// @dev gets the amount of SKILL that is risked per duel by tier
    function getDuelCostByTier(uint8 tier) internal view returns (uint256) {
        if (tier == 20) {
            return game.usdToSkill(_baseWagerUSD);
        }

        int128 tierExtra = ABDKMath64x64
            .divu(tier.mul(100), 100)
            .mul(_tierWagerUSD);

        return game.usdToSkill(_baseWagerUSD.add(tierExtra));
    }

    /// @dev gets the arena tier of a character (tiers are 1-10, 11-20, etc...)
    function getArenaTier(uint256 characterID) public view returns (uint8) {
        uint8 level = characters.getLevel(characterID);
        return getArenaTierForLevel(level);
    }

    function getArenaTierForLevel(uint8 level) internal pure returns (uint8) {
        return uint8(level.div(10));
    }

    /// @dev get an attacker's opponent
    function getOpponent(uint256 attackerID) public view returns (uint256) {
        return matchByFinder[attackerID].defenderID;
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
    function _assignOpponent(uint256 characterID, uint8 tier) private {
        EnumerableSet.UintSet
            storage matchableCharacters = _matchableCharactersByTier[tier];

        require(matchableCharacters.length() != 0, "L");

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
            uint256 index = (randomIndex + i) % matchableCharactersCount;
            uint256 candidateID = matchableCharacters.at(index);

            if (candidateID == characterID) {
                if (matchableCharactersCount == 1) {
                    break;
                }
                if (
                    matchableCharacters.at(matchableCharactersCount - 1) ==
                    candidateID
                ) {
                    candidateID = matchableCharacters.at(0);
                } else {
                    candidateID = matchableCharacters.at(index + 1);
                }
            }
            if (
                _ownerByCharacter[candidateID] == msg.sender
            ) {
                continue;
            }

            foundOpponent = true;
            opponentID = candidateID;
            break;
        }

        require(foundOpponent, "E");

        matchByFinder[characterID] = Match(
            characterID,
            opponentID,
            block.timestamp
        );
        finderByOpponent[opponentID] = characterID;
        _matchableCharactersByTier[tier].remove(characterID);
        _matchableCharactersByTier[tier].remove(opponentID);
    }

    /// @dev removes a character from arena and clears it's matches
    function _removeCharacterFromArena(uint256 characterID, uint8 tier)
        private
        characterInArena(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];

        uint256 weaponID = fighter.weaponID;
        uint256 shieldID = fighter.shieldID;

        excessWagerByCharacter[characterID] = fighter.wager;

        // Shield removed first before the fighter is deleted
        if (fighter.useShield) {
            isShieldInArena[shieldID] = false;
            shields.setNftVar(shieldID, 1, 0);
        }

        delete fighterByCharacter[characterID];
        delete matchByFinder[characterID];

        if (_matchableCharactersByTier[tier].contains(characterID)) {
            _matchableCharactersByTier[tier].remove(characterID);
        }

        isCharacterInArena[characterID] = false;
        isWeaponInArena[weaponID] = false;

        characters.setNftVar(characterID, 1, 0);
        weapons.setNftVar(weaponID, 1, 0);
    }

    function _getCharacterPowerRoll(Duelist memory character, uint8 opponentTrait)
        private
        view
        returns (uint24)
    {
        uint24 playerFightPower = getCharacterPower(character.ID);

        Fighter memory fighter = fighterByCharacter[character.ID];
        uint256 weaponID = fighter.weaponID;
        uint256 seed = randoms.getRandomSeedUsingHash(
            _ownerByCharacter[character.ID],
            blockhash(block.number - 1)
        );

        uint8 weaponTrait = weapons.getTrait(weaponID);

        int128 playerTraitBonus = _getPVPTraitBonusAgainst(
            character.trait,
            weaponTrait,
            opponentTrait
        );

        uint256 playerPower = RandomUtil.plusMinus30PercentSeeded(
            playerFightPower,
            seed
        );

        return uint24(playerTraitBonus.mulu(playerPower));
    }

    function getCharacterPower(uint256 characterID)
        public
        view
        characterInArena(characterID)
        returns (uint24) 
    {
        int128 bonusShieldStats;
        
        (
            ,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            
        ) = weapons.getFightData(fighterByCharacter[characterID].weaponID, characters.getTrait(characterID));

        if (fighterByCharacter[characterID].useShield) {
            // we set bonus shield stats as 0.2
            bonusShieldStats = _getShieldStats(characterID).sub(1).mul(20).div(100);
        }

        return (   
            Common.getPlayerPowerBase100(
                Common.getPowerAtLevel(characters.getLevel(characterID)),
                (weaponMultFight.add(bonusShieldStats)),
                weaponBonusPower)
        );
    }

    /// @dev returns the amount of matcheable characters
    function getMatchablePlayerCount(uint256 characterID) external view returns(uint){
        uint8 tier = getArenaTier(characterID);
        return _matchableCharactersByTier[tier].length();   
    }

    function _getPVPTraitBonusAgainst(
        uint8 characterTrait,
        uint8 weaponTrait,
        uint8 opponentTrait
    ) private view returns (int128) {
        int128 traitBonus = ABDKMath64x64.fromUInt(1);
        int128 fightTraitBonus = game.fightTraitBonus();
        int128 charTraitFactor = ABDKMath64x64.divu(50, 100);
        if (characterTrait == weaponTrait) {
            traitBonus = traitBonus.add(fightTraitBonus.mul(3));
        }

        // We apply 50% of char trait bonuses because they are applied twice (once per fighter)
        if (
            Common.isTraitEffectiveAgainst(characterTrait, opponentTrait)
        ) {
            traitBonus = traitBonus.add(fightTraitBonus.mul(charTraitFactor));
        } else if (
            Common.isTraitEffectiveAgainst(opponentTrait, characterTrait)
        ) {
            traitBonus = traitBonus.sub(fightTraitBonus.mul(charTraitFactor));
        }
        return traitBonus;
    }

    function _getShieldStats(uint256 characterID)
        private
        view
        returns (int128)
    {
        uint8 trait = characters.getTrait(characterID);
        uint256 shieldID = fighterByCharacter[characterID].shieldID;
        int128 shieldMultFight = shields.getDefenseMultiplierForTrait(shieldID, trait);
        return (shieldMultFight);
    }

    function setBaseWagerInCents(uint256 cents) external restricted {
        _baseWagerUSD = ABDKMath64x64.divu(cents, 100);
    }

    function setTierWagerInCents(uint256 cents) external restricted {
        _tierWagerUSD = ABDKMath64x64.divu(cents, 100);
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

    function setDecisionSeconds(uint256 secs) external restricted {
        decisionSeconds = secs;
    }

    function setArenaAccess(uint256 accessFlags) external restricted {
        arenaAccess = accessFlags;
    }

    function setDuelOffsetCost(uint256 cost) external restricted {
        duelOffsetCost = cost;
    }

    function setPvpBotAddress(address payable botAddress) external restricted {
        pvpBotAddress = botAddress;
    }

    // Note: The following are debugging functions, they can be muted to save contract size

    function forceRemoveCharacterFromArena(uint256 characterID)
        external 
        restricted
        characterNotUnderAttack(characterID)
        characterNotInDuel(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];
        uint8 tier;
        
        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        uint256 wager = fighter.wager;
        uint256 entryWager = getEntryWager(characterID);

        if (matchByFinder[characterID].createdAt != 0) {
            if (wager < entryWager.mul(withdrawFeePercent).div(100)) {
                wager = 0;
            } else {
                wager = wager.sub(entryWager.mul(withdrawFeePercent).div(100));
            }
        }

        _removeCharacterFromArena(characterID, tier);

        excessWagerByCharacter[characterID] = 0;
        fighter.wager = 0;

        skillToken.safeTransfer(characters.ownerOf(characterID), wager);
    }

    // function clearDuelQueue(uint256 length) external restricted {
    //     for (uint256 i = 0; i < length; i++) {
    //         if (matchByFinder[_duelQueue.at(i)].defenderID > 0) {
    //             isDefending[matchByFinder[_duelQueue.at(i)].defenderID] = false;
    //         }

    //         _duelQueue.remove(_duelQueue.at(i));
    //     }

    //     isDefending[0] = false;
    // }
}
