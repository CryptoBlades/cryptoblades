pragma solidity ^0.6.0;
// TODO: Clean unused imports after splitting contract
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./PvpCore.sol";

contract PvpRankings is Initializable, AccessControlUpgradeable {
    using SafeMath for uint8;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;
    Characters public characters;
    IERC20 public skillToken;
    PvpCore public pvpcore;

    /// @dev how much of a duel's bounty is sent to the rankings pool
    uint8 private _rankingsPoolTaxPercent;
    /// @dev amount of points earned by winning a duel
    uint8 public winningPoints;
    /// @dev amount of points subtracted by losing duel
    uint8 public losingPoints;
    /// @dev max amount of top characters by tier
    uint8 private _maxTopCharactersPerTier;
    /// @dev current ranked season
    uint256 public currentRankedSeason;
    /// @dev timestamp of when the current season started
    uint256 public seasonStartedAt;
    /// @dev interval of ranked season restarts
    uint256 public seasonDuration;
    /// @dev amount of skill due for game coffers from tax
    uint256 public gameCofferTaxDue;
    /// @dev percentages of ranked prize distribution by fighter rank (represented as index)
    uint256[] public prizePercentages;

    /// @dev season number associated to character
    mapping(uint256 => uint256) public seasonByCharacter;
    /// @dev ranking points by character
    mapping(uint256 => uint256) public rankingPointsByCharacter;
    /// @dev accumulated skill pool per tier
    mapping(uint8 => uint256) public rankingsPoolByTier;
    /// @dev funds available for withdrawal by address
    mapping(address => uint256) private _rankingRewardsByPlayer;
    /// @dev top ranking characters by tier
    mapping(uint8 => uint256[]) private _topRankingCharactersByTier;

    event SeasonRestarted(
        uint256 indexed newSeason,
        uint256 timestamp
    );

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender));
    }

    function initialize(
        address gameContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        skillToken = IERC20(game.skillToken());

        _rankingsPoolTaxPercent = 15;
        winningPoints = 5;
        losingPoints = 3;
        _maxTopCharactersPerTier = 4;
        currentRankedSeason = 1;
        seasonStartedAt = block.timestamp;
        seasonDuration = 7 days;
        prizePercentages.push(60);
        prizePercentages.push(30);
        prizePercentages.push(10);
    }

    function withdrawRankedRewards() external {
        uint256 amountToTransfer = _rankingRewardsByPlayer[msg.sender];

        if (amountToTransfer > 0) {
            _rankingRewardsByPlayer[msg.sender] = 0;

            skillToken.safeTransfer(msg.sender, amountToTransfer);
        }
    }

    function restartRankedSeason() external restricted {
        uint256[] memory duelQueue = pvpcore.getDuelQueue();

        if (duelQueue.length > 0) {
            pvpcore.performDuels(duelQueue);
        }

        // Loops over 20 tiers. Should not be reachable anytime in the foreseeable future
        for (uint8 i = 0; i <= 20; i++) {
            if (_topRankingCharactersByTier[i].length == 0) {
                continue;
            }

            uint256 difference = 0;

            if (
                _topRankingCharactersByTier[i].length <= prizePercentages.length
            ) {
                difference =
                    prizePercentages.length -
                    _topRankingCharactersByTier[i].length;
            }

            // If there are less players than top positions, excess is transferred to top 1
            if (
                _topRankingCharactersByTier[i].length < prizePercentages.length
            ) {
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
                _rankingRewardsByPlayer[topOnePlayer] = _rankingRewardsByPlayer[
                    topOnePlayer
                ].add((rankingsPoolByTier[i].mul(excessPercentage)).div(100));
            }

            // We assign rewards normally to all possible players
            for (uint8 h = 0; h < prizePercentages.length - difference; h++) {
                _assignRewards(
                    _topRankingCharactersByTier[i][h],
                    h,
                    rankingsPoolByTier[i]
                );
            }

            // We reset ranking prize pools
            rankingsPoolByTier[i] = 0;
 
            // We reset top players' scores
            for (uint256 k = 0; k < _topRankingCharactersByTier[i].length; k++) {
                rankingPointsByCharacter[_topRankingCharactersByTier[i][k]] = 0;
            }
        }

        currentRankedSeason = currentRankedSeason.add(1);
        seasonStartedAt = block.timestamp;

        emit SeasonRestarted(
                currentRankedSeason,
                seasonStartedAt
            );
    }

    // Requires 3 top characters, less than that will produce unintended consequences
    // Short-term solution function, delete once used.
    function forceRestartRankedSeason() external restricted {
        uint256[] memory duelQueue = pvpcore.getDuelQueue();

        if (duelQueue.length > 0) {
            pvpcore.performDuels(duelQueue);
        }

        // NOTE: TIERS HARDCODED FOR SPECIFIC ERROR
        for (uint8 i = 3; i <= 19; i++) {
            if (_topRankingCharactersByTier[i].length == 0) {
                continue;
            }

            // We assign rewards normally to all possible players
            for (uint8 h = 0; h < prizePercentages.length; h++) {
                _assignRewards(
                    _topRankingCharactersByTier[i][h],
                    h,
                    rankingsPoolByTier[i]
                );
            }

            // We reset ranking prize pools
            rankingsPoolByTier[i] = 0;
 
            // We reset top players' scores
            for (uint256 k = 0; k < _topRankingCharactersByTier[i].length; k++) {
                rankingPointsByCharacter[_topRankingCharactersByTier[i][k]] = 0;
            }
        }

        currentRankedSeason = currentRankedSeason.add(1);
        seasonStartedAt = block.timestamp;

        emit SeasonRestarted(
                currentRankedSeason,
                seasonStartedAt
            );
    }

    function forceAssignRewards(
        uint256 characterID,
        uint8 position,
        uint256 pool
    ) external restricted {
        uint256 percentage = prizePercentages[position];
        uint256 amountToTransfer = (pool.mul(percentage)).div(100);
        address playerToTransfer = characters.ownerOf(characterID);

        _rankingRewardsByPlayer[playerToTransfer] = _rankingRewardsByPlayer[
            playerToTransfer
        ].add(amountToTransfer);
    }

    function clearTierTopCharacters(uint8 tier) external restricted {
        for (uint256 k = 0; k < _topRankingCharactersByTier[tier].length; k++) {
            rankingPointsByCharacter[_topRankingCharactersByTier[tier][k]] = 0;
        }
        delete _topRankingCharactersByTier[tier];
        rankingsPoolByTier[tier] = 0;
    }

    function _processWinner(uint256 winnerID, uint8 tier) private {
        uint256 rankingPoints = rankingPointsByCharacter[winnerID];
        uint256[] storage topRankingCharacters = _topRankingCharactersByTier[
            tier
        ];
        uint256 winnerPosition;
        bool winnerInRanking;

        // check if winner is withing the top 4
        for (uint8 i = 0; i < topRankingCharacters.length; i++) {
            if (winnerID == topRankingCharacters[i]) {
                winnerPosition = i;
                winnerInRanking = true;
                break;
            }
        }
        
        // if the winner is not in the top characters we then compare it to the last character of the top rank, swapping positions if the condition is met
        if (
            !winnerInRanking &&
            rankingPoints >=
            rankingPointsByCharacter[
                topRankingCharacters[topRankingCharacters.length - 1]
            ]
        ) {
            topRankingCharacters[topRankingCharacters.length - 1] = winnerID;
            winnerPosition = topRankingCharacters.length - 1;
        }

        for (winnerPosition; winnerPosition > 0; winnerPosition--) {
            if (
                rankingPointsByCharacter[
                    topRankingCharacters[winnerPosition]
                ] >=
                rankingPointsByCharacter[
                    topRankingCharacters[winnerPosition - 1]
                ]
            ) {
                uint256 oldCharacter = topRankingCharacters[winnerPosition - 1];
                topRankingCharacters[winnerPosition - 1] = winnerID;
                topRankingCharacters[winnerPosition] = oldCharacter;
            } else {
                break;
            }
        }
    }

    function _processLoser(uint256 loserID, uint8 tier) private {
        uint256 rankingPoints = rankingPointsByCharacter[loserID];
        uint256[] storage ranking = _topRankingCharactersByTier[tier];
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
                    rankingPointsByCharacter[ranking[loserPosition + 1]]
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

    function getTierTopCharacters(uint8 tier)
        external
        view
        returns (uint256[] memory)
    {
        uint256 arrayLength;
        // we return only the top 3 players, returning the array without the pivot ranker if it exists
        if (
            _topRankingCharactersByTier[tier].length == _maxTopCharactersPerTier
        ) {
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

    function getPlayerPrizePoolRewards() external view returns (uint256) {
        return _rankingRewardsByPlayer[msg.sender];
    }

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

    function getDuelBountyDistribution(uint256 duelCost)
        external
        view
        returns (uint256, uint256)
    {
        uint256 bounty = duelCost.mul(2);
        uint256 poolTax = _rankingsPoolTaxPercent.mul(bounty).div(100);

        uint256 reward = bounty.sub(poolTax).sub(duelCost);

        return (reward, poolTax);
    }

    function fillGameCoffers() external restricted {
        skillToken.safeTransfer(address(game), gameCofferTaxDue);
        game.trackIncome(gameCofferTaxDue);
        gameCofferTaxDue = 0;
    }

    function increaseRankingsPool(uint8 tier, uint256 amount) external restricted {
        rankingsPoolByTier[tier] = rankingsPoolByTier[tier].add(amount);
    }

    function changeRankingPoints(uint256 characterID, uint256 points) external restricted {
        rankingPointsByCharacter[characterID] = points;
    }

    function handleEnterArena(uint256 characterID, uint8 tier) external restricted {
        bool isCharacterInTopRanks;
    
        for (uint i = 0; i < _topRankingCharactersByTier[tier].length; i++) {
            if (characterID == _topRankingCharactersByTier[tier][i]) {
                isCharacterInTopRanks = true;
            }
        }

        if (
            _topRankingCharactersByTier[tier].length <
            _maxTopCharactersPerTier && !isCharacterInTopRanks
        ) {
            _topRankingCharactersByTier[tier].push(characterID);
        }

        if (seasonByCharacter[characterID] != currentRankedSeason) {
            rankingPointsByCharacter[characterID] = 0;
            seasonByCharacter[characterID] = currentRankedSeason;
        }
    }

    function handlePrepareDuel(uint256 characterID) external restricted {
        if (seasonByCharacter[characterID] != currentRankedSeason) {
            rankingPointsByCharacter[characterID] = 0;
            seasonByCharacter[characterID] = currentRankedSeason;
        }
    }

    function handlePerformDuel(uint256 winnerID, uint256 loserID, uint256 bonusRank, uint8 tier, uint256 poolTax) external restricted {
        rankingPointsByCharacter[winnerID] = rankingPointsByCharacter[
                winnerID
        ].add(winningPoints.add(bonusRank));

        // Mute the ranking loss from users in pvpRankings
        // if (rankingPointsByCharacter[loserID] <= losingPoints) {
        //     rankingPointsByCharacter[loserID] = 0;
        // } else {
        //     rankingPointsByCharacter[loserID] = rankingPointsByCharacter[
        //         loserID
        //     ].sub(losingPoints);
        // }

        _processWinner(winnerID, tier);
        _processLoser(loserID, tier);

        rankingsPoolByTier[tier] = rankingsPoolByTier[
            tier
        ].add(poolTax / 2);

        gameCofferTaxDue += poolTax / 2;
    }

    // SETTERS

    function setPrizePercentage(uint256 index, uint256 value)
        external
        restricted
    {
        prizePercentages[index] = value;
    }

    function setRankingsPoolTaxPercent(uint8 percent) external restricted {
        _rankingsPoolTaxPercent = percent;
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

    function setPvpCoreAddress(address pvpCoreContract) external restricted {
        pvpcore = PvpCore(pvpCoreContract);
    }
}