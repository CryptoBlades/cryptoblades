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

    Characters public characters;
    Weapons public weapons;


    function initialize(Characters _characters, Weapons _weapons) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        characters = _characters;
        weapons = _weapons;
        nextQuestID = 1;
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    modifier questsEnabled() {
        require(vars[VAR_CONTRACT_ENABLED] == 1, "Quests are disabled");
        _;
    }

    function assertOnQuest(uint256[] memory questData) internal pure {
        require(questData[0] != 0, "Not on quest");
    }

    function assertNotOnQuest(uint256[] memory questData) internal pure {
        require(questData[0] == 0, "Already on quest");
    }

    function assertQuestCompleted(uint256[] memory questData) internal view {
        require(questData[1] >= questList[questData[0]].requirementAmount, "Quest not completed");
    }

    uint8 public constant VAR_CONTRACT_ENABLED = 1;
    mapping(uint256 => uint256) public vars;

    uint256 public nextQuestID;

    struct Quest {
        uint256 id;
        uint8 tier;
        RequirementType requirementType;
        RewardType rewardType;
        RewardRarity rewardRarity;
        uint256 requirementAmount;
        uint256 rewardAmount;
        uint256 reputationAmount;
    }

    enum RequirementType{NONE, RAID}
    enum RewardType{SWORD, JUNK}
    enum RewardRarity{COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

    // have quests rarities on certain indexes (0 - common, 1 - uncommon, 2 - rare, 3 - epic)
    // or have quests in different arrays and join them on allQuestsList
    mapping(uint32 => Quest[]) public quests;
    mapping(uint256 => Quest) public questList;
    //    mapping(uint32 => uint32[]) public rewardsTypes;
    //rewardsTypes[0].push(99);
    //    mapping(uint32 => uint32[]) public requirementsTypes;
    //1 star sword
    //2 star sword
    //3 star sword
    //4 star sword
    //5 star sword
    //1 star junk
    //2 star junk
    //3 star junk
    //4 star junk
    //5 star junk
    //stamina
    //raid
    //LB
    //4B
    //5B

    //    mapping(uint32 => Quest) public commonQuestsList;
    //    mapping(uint32 => Quest) public uncommonQuestsList;
    //    mapping(uint32 => Quest) public rareQuestsList;
    //    mapping(uint32 => Quest) public epicQuestsList;

    //    uint256[3] public constant CHARACTER_QUEST_DATA_KEYS = [100,101,102];
    //    uint256 public constant NFTVAR_SIMPLEQUEST_ID = 100;
    //    uint256 public constant NFTVAR_SIMPLEQUEST_PROGRESS = 101;
    //    uint256 public constant NFTVAR_SIMPLEQUEST_TYPE = 102;
    //    uint256 public constant NFTVAR_REPUTATION = 103;

    event QuestComplete(uint256 indexed questID, uint256 indexed characterID);
    event QuestAssigned(uint256 indexed questID, uint256 indexed characterID);

    //Quest example: tier = 1, id = TBA, requirementType = 1, requirementAmount = 2, rewardType = 1, rewardAmount = 1, reputationAmount = 12
    // do 2 raids for 1x3* sword
    function addNewQuest(uint8 tier, RequirementType requirementType, RewardType rewardType, RewardRarity rewardRarity, uint256 requirementAmount, uint256 rewardAmount, uint256 reputationAmount) public {
        quests[tier].push(Quest(0, tier, requirementType, rewardType, rewardRarity, requirementAmount, rewardAmount, reputationAmount));
    }

    function deleteQuest(uint8 tier, uint32 index) public {
        delete quests[tier][index];
    }

    function getCharacterQuestData(uint256 characterID) public view returns (uint256[] memory) {
        uint256[] memory questDataKeys = new uint256[](4);
        questDataKeys[0] = characters.NFTVAR_SIMPLEQUEST_ID();
        questDataKeys[1] = characters.NFTVAR_SIMPLEQUEST_PROGRESS();
        questDataKeys[2] = characters.NFTVAR_SIMPLEQUEST_TYPE();
        questDataKeys[3] = characters.NFTVAR_REPUTATION();
        return characters.getNFTVars(characterID, questDataKeys);
    }

    function assignNewQuest(uint256 characterID) public returns (uint256) {
        uint256[] memory questData = getCharacterQuestData(characterID);
        assertNotOnQuest(questData);
        // tier should be chosen by random, based on % for reputation level, for now, we take common
        Quest memory quest = getNewQuest(0);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_ID(), quest.id);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), 0);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_TYPE(), uint256(quest.requirementType));
        emit QuestAssigned(quest.id, characterID);
        return quest.id;
    }

    function getNewQuest(uint8 tier) private returns (Quest memory) {
        // get random index from 0 to length - 1, which will indicate predetermined quest
        uint32 index = 0;
        // uint32 index = random(quests.length);
        Quest memory quest = quests[tier][index];
        quest.id = nextQuestID++;
        questList[quest.id] = quest;
        // should assign new ID to quest and save it in questsList array (all quests are there)
        return quest;
    }

    function completeQuest(uint256 characterID) external {
        uint256[] memory questData = getCharacterQuestData(characterID);
        assertOnQuest(questData);
        assertQuestCompleted(questData);
        uint256 questID = questData[0];
        uint256 currentReputation = questData[3];
        // reward for completing quest
        rewardQuest(questID, characterID);
        characters.setNftVar(characterID, characters.NFTVAR_REPUTATION(), currentReputation + questList[questID].reputationAmount);
        // clear quest data
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_ID(), 0);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), 0);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_TYPE(), 0);

        emit QuestComplete(questID, characterID);
        // after quest competition, assign new quest to the character
        assignNewQuest(characterID);
    }

    function rewardQuest(uint256 questID, uint256 characterID) private {
        Quest memory quest = questList[questID];
        if (quest.rewardType == RewardType.SWORD) {// do a package, like, rewardType >= 1 && rewardType <= 4 and use the same mintWeaponWithStars based on that
            // for now, rewardType = 1 means 3* sword
            // stars = 2 for 3* sword
            // random seed
            // random element = 100??
            for (uint8 i = 0; i < quest.rewardAmount; i++) {
                uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))));
                uint256 weaponID = weapons.mintWeaponWithStars(characters.ownerOf(characterID), uint256(quest.rewardRarity), seed / 100, 100);
            }

        }
    }

    //    function requestQuest(uint256 characterID) external questsEnabled {
    //        uint256[] memory questData = getCharacterQuestData(characterID);
    //        assertOnQuest(questData);
    //        // submits a seed request with a randoms ID (this randoms ID is shared with all in a block)
    //        // it will complete by the randoms bot/contract automatically
    //    }

//    function submitProgress(uint256 characterID, uint256 amount) external questsEnabled {
//        uint256[] memory questData = getCharacterQuestData(characterID);
//        assertOnQuest(questData);
//    }

//    function submitProgressForced(uint256 characterID, uint256 amount) external restricted questsEnabled {
//
//    }

}
