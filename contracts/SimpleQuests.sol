pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./Promos.sol";
import "./util.sol";
import "./items/Junk.sol";

contract SimpleQuests is Initializable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    
    function initialize() public initializer {
        
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier questsEnabled() {
        _questsEnabled();
        _;
    }

    function _questsEnabled() internal view {
        require(vars[VAR_CONTRACT_ENABLED] == 1, "Quests are disabled");
    }

    function assertOnQuest(uint256[3] memory questData, uint256 id) internal view {
        // pass 0 as ID to check if not on quest
        require(questData[0] == id, "On quest revert");
    }
    
    uint8 public constant VAR_CONTRACT_ENABLED = 1;
    mapping(uint256 => uint256) public vars;

    struct Quest {
        uint8 tier;
        uint32 id;
        uint32 requirementType;
        uint32 rewardType;
        uint256 requirementAmount;
        uint256 rewardAmount;
    }

    mapping(uint32 => Quest) public questList;

    uint256[3] public constant CHARACTER_QUEST_DATA_KEYS = [100,101,102];

    event QuestComplete(uint256 indexed questID, uint256 indexed characterID);

    function getQuestID(uint256 characterID) external view returns(uint32) {
        // doubles as an "are we on a quest" check
        return characters.getNftVar(characters.NFTVAR_SIMPLEQUEST_ID); // if 0, we are not on a quest
    }

    function getCharacterQuestData(uint256 characterID) public view returns(uint256[3] memory) {
        return characters.getNFTVars(characterID, CHARACTER_QUEST_DATA_KEYS);
    }

    function requestQuest(uint256 characterID) external questsEnabled {
        uint256[3] questData = getCharacterQuestData
        assertOnQuest(characterID, 0);
        // submits a seed request with a randoms ID (this randoms ID is shared with all in a block)
        // it will complete by the randoms bot/contract automatically
    }

    function submitProgress(uint256 characterID, uint256 amount) external questsEnabled {
        assertOnQuest()
    }

    function submitProgressForced(uint256 characterID, uint256 amount) external restricted questsEnabled {

    }

}