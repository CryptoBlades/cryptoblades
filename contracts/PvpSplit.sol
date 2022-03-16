pragma solidity ^0.6.0;
// TODO: Clean unused imports after splitting contract
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
import "./PvpArena.sol";

contract PvpSplit is Initializable, AccessControlUpgradeable {
    // TODO: Clean
    // using EnumerableSet for EnumerableSet.UintSet;
    // using SafeMath for uint8;
    // using SafeMath for uint24;
    // using SafeMath for uint256;
    // using ABDKMath64x64 for int128;
    // using SafeERC20 for IERC20;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    // CryptoBlades public game;
    // Characters public characters;
    // Weapons public weapons;
    // Shields public shields;
    // IERC20 public skillToken;
    // IRandoms public randoms;
    PvpArena public pvparena;

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

    modifier isOwnedCharacter(uint256 characterID) {
        require(characters.ownerOf(characterID) == msg.sender);
        _;
    }

}