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
    Junk public junk;


    function initialize(Characters _characters, Weapons _weapons, Junk _junk) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        characters = _characters;
        weapons = _weapons;
        junk = _junk;
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
        Rarity requirementRarity;
        uint256 requirementAmount;
        RewardType rewardType;
        Rarity rewardRarity;
        uint256 rewardAmount;
        uint256 reputationAmount;
    }

    enum RequirementType{NONE, RAID, WEAPON, JUNK}
    enum RewardType{WEAPON, JUNK}
    enum Rarity{COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

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
    event QuestProgressed(uint256 indexed questID, uint256 indexed characterID);

    //Quest example: tier = 1, id = TBA, requirementType = 1, requirementAmount = 2, rewardType = 1, rewardAmount = 1, reputationAmount = 12
    // do 2 raids for 1x3* sword
    function addNewQuest(uint8 tier, RequirementType requirementType, Rarity requirementRarity, uint256 requirementAmount,
        RewardType rewardType, Rarity rewardRarity, uint256 rewardAmount, uint256 reputationAmount) public {
        quests[tier].push(Quest(0, tier,
            requirementType, requirementRarity, requirementAmount,
            rewardType, rewardRarity, rewardAmount, reputationAmount));
    }

    function getQuestArrayLength(uint8 tier) public view returns (uint256) {
        return quests[tier].length;
    }

    //move element to be deleted at the end, pop it
    function deleteQuest(uint8 tier, uint32 index) public {
        require(index < quests[tier].length, "Index out of bounds");
        quests[tier][index] = quests[tier][quests[tier].length-1];
        quests[tier].pop();
    }

    function getCharacterQuestData(uint256 characterID) public view returns (uint256[] memory) {
        uint256[] memory questDataKeys = new uint256[](4);
        questDataKeys[0] = characters.NFTVAR_SIMPLEQUEST_ID();
        questDataKeys[1] = characters.NFTVAR_SIMPLEQUEST_PROGRESS();
        questDataKeys[2] = characters.NFTVAR_SIMPLEQUEST_TYPE();
        questDataKeys[3] = characters.NFTVAR_REPUTATION();
        return characters.getNFTVars(characterID, questDataKeys);
    }

    function requestQuest(uint256 characterID) public returns (uint256) {
        uint256[] memory questData = getCharacterQuestData(characterID);
        assertNotOnQuest(questData);
        return assignNewQuest(characterID);
    }

    function assignNewQuest(uint256 characterID) private returns (uint256) {
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
        // uint32 index = random(quests.length);
        Quest memory quest = quests[tier][quests[tier].length-1];
        quest.id = nextQuestID++;
        questList[quest.id] = quest;
        // should assign new ID to quest and save it in questsList array (all quests are there)
        return quest;
    }

    // free for now, later should be restrained and user has to pay stamina or something
    function skipQuest(uint256 characterID) public returns (uint256) {
        return assignNewQuest(characterID);
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
        if (quest.rewardType == RewardType.WEAPON) {// do a package, like, rewardType >= 1 && rewardType <= 4 and use the same mintWeaponWithStars based on that
            // for now, rewardType = 1 means 3* sword
            // stars = 2 for 3* sword
            // random seed
            // random element = 100??
            for (uint8 i = 0; i < quest.rewardAmount; i++) {
                uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - i - 1))));
                uint256 weaponID = weapons.mintWeaponWithStars(characters.ownerOf(characterID), uint256(quest.rewardRarity), seed / 100, 100);
            }
        } else if (quest.rewardType == RewardType.JUNK) {
            for (uint8 i = 0; i < quest.rewardAmount; i++) {
                junk.mint(msg.sender, uint8(quest.rewardRarity));
            }
        }
    }

    function submitProgress(uint256 characterID, uint256[] memory tokenIds) public {
        uint256[] memory questData = getCharacterQuestData(characterID);
        assertOnQuest(questData);
        Quest memory quest = questList[questData[0]];
        if (quest.requirementType == RequirementType.WEAPON) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                if (weapons.ownerOf(tokenID) != msg.sender) {
                    revert("You don't own this weapon");
                }
                if ((weapons.getStars(tokenID) - 1) != uint256(quest.requirementRarity)) {
                    revert("Wrong weapon rarity");
                }
                weapons.burnWithoutDust(tokenID);
                uint currentProgress = characters.getNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS());
                characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), ++currentProgress);
                emit QuestProgressed(questData[0], characterID);
            }
        } else if (quest.requirementType == RequirementType.JUNK) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                if (junk.ownerOf(tokenID) != msg.sender) {
                    revert("You don't own this junk");
                }
                if (junk.getStars(tokenID) != uint256(quest.requirementRarity)) {
                    revert("Wrong junk rarity");
                }
                junk.burn(tokenID);
                uint currentProgress = characters.getNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS());
                characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), ++currentProgress);
                emit QuestProgressed(questData[0], characterID);
            }
        }
        // should I automatically complete the quest and assign new one? or should I let user complete quest later
    }

}
