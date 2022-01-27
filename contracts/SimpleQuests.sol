pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./shields.sol";
import "./Promos.sol";
import "./util.sol";
import "./items/Junk.sol";
import "./items/RaidTrinket.sol";
import "./SafeRandoms.sol";

contract SimpleQuests is Initializable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    uint256 public constant SEED_RANDOM_QUEST = uint(keccak256("SEED_RANDOM_QUEST"));

    Characters public characters;
    Weapons public weapons;
    Junk public junk;
    RaidTrinket public trinket;
    Shields public shields;
    SafeRandoms public safeRandoms;

    function initialize(Characters _characters, Weapons _weapons, Junk _junk, RaidTrinket _trinket, Shields _shields, SafeRandoms _safeRandoms) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        characters = _characters;
        weapons = _weapons;
        junk = _junk;
        trinket = _trinket;
        shields = _shields;
        safeRandoms = _safeRandoms;
        nextQuestID = 1;
        vars[VAR_COMMON_TIER] = 0;
        vars[VAR_UNCOMMON_TIER] = 1;
        vars[VAR_RARE_TIER] = 2;
        vars[VAR_EPIC_TIER] = 3;
        vars[VAR_LEGENDARY_TIER] = 4;
        staminaCost = 40;
        vars[VAR_REPUTATION_LEVEL_2] = 1000;
        vars[VAR_REPUTATION_LEVEL_3] = 2000;
        vars[VAR_REPUTATION_LEVEL_4] = 5000;
        vars[VAR_REPUTATION_LEVEL_5] = 10000;
        // 100% common chance
        questTierChances[0] = [100, 100, 100, 100];
        // 15% uncommon chance
        questTierChances[1] = [85, 100, 100, 100];
        // 20% uncommon, 3% rare
        questTierChances[2] = [77, 97, 100, 100];
        questTierChances[3] = [69, 94, 100, 100];
        // 0% legendary
        questTierChances[4] = [66, 93, 99, 100];
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    modifier questsEnabled() {
        require(vars[VAR_CONTRACT_ENABLED] == 1, "Quests are disabled");
        _;
    }

    function assertOnQuest(uint256 characterID) internal view {
        require(characterQuest[characterID] != 0, "Not on quest");
    }

    function assertNotOnQuest(uint256 characterID) internal view {
        require(characterQuest[characterID] == 0, "Already on quest");
    }

    function assertQuestCompleted(uint256 characterID, uint256 questProgress) internal view {
        require(questProgress >= questList[characterQuest[characterID]].requirementAmount, "Quest not completed");
    }


    uint8 public constant VAR_COMMON_TIER = 0;
    uint8 public constant VAR_UNCOMMON_TIER = 1;
    uint8 public constant VAR_RARE_TIER = 2;
    uint8 public constant VAR_EPIC_TIER = 3;
    uint8 public constant VAR_LEGENDARY_TIER = 4;
    uint8 public constant VAR_CONTRACT_ENABLED = 9;
    uint8 public constant VAR_REPUTATION_LEVEL_2 = 20;
    uint8 public constant VAR_REPUTATION_LEVEL_3 = 21;
    uint8 public constant VAR_REPUTATION_LEVEL_4 = 22;
    uint8 public constant VAR_REPUTATION_LEVEL_5 = 23;
    uint8 public staminaCost;
    mapping(uint256 => uint256) public vars;

    uint256 public nextQuestID;

    struct Quest {
        uint256 id;
        Rarity tier;
        RequirementType requirementType;
        Rarity requirementRarity;
        uint256 requirementAmount;
        RewardType rewardType;
        Rarity rewardRarity;
        uint256 rewardAmount;
        uint256 reputationAmount;
    }

    enum RequirementType{NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, RAID}
    enum RewardType{NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, EXPERIENCE}
    enum Rarity{COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

    // have quests rarities on certain indexes (0 - common, 1 - uncommon, 2 - rare, 3 - epic, 4 - legendary (optional))
    // promo arrays are accordingly (10 - common, 11 - uncommon, 12 - rare, 13 - epic, 14 - legendary (optional))
    mapping(uint256 => Quest[]) public quests;
    mapping(uint256 => Quest) public questList;
    mapping(uint256 => uint256) public characterQuest;
    mapping(uint256 => uint256[4]) public questTierChances;

    //    uint256[3] public constant CHARACTER_QUEST_DATA_KEYS = [101,102,103];
    //    uint256 public constant NFTVAR_SIMPLEQUEST_PROGRESS = 101;
    //    uint256 public constant NFTVAR_SIMPLEQUEST_TYPE = 102;
    //    uint256 public constant NFTVAR_REPUTATION = 103;

    event QuestComplete(uint256 indexed questID, uint256 indexed characterID);
    event QuestAssigned(uint256 indexed questID, uint256 indexed characterID);
    event QuestProgressed(uint256 indexed questID, uint256 indexed characterID);

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for (uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    function getVars(uint256[] calldata varFields) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](varFields.length);
        for (uint i = 0; i < varFields.length; i++) {
            result[i] = vars[varFields[i]];
        }
        return result;
    }

    function addNewQuest(Rarity tier, RequirementType requirementType, Rarity requirementRarity, uint256 requirementAmount,
        RewardType rewardType, Rarity rewardRarity, uint256 rewardAmount, uint256 reputationAmount) public {
        quests[uint8(tier)].push(Quest(0, tier,
            requirementType, requirementRarity, requirementAmount,
            rewardType, rewardRarity, rewardAmount, reputationAmount));
    }

    function addNewPromoQuest(Rarity tier, RequirementType requirementType, Rarity requirementRarity, uint256 requirementAmount,
        RewardType rewardType, Rarity rewardRarity, uint256 rewardAmount, uint256 reputationAmount) public {
        quests[uint8(tier) + 10].push(Quest(0, tier,
            requirementType, requirementRarity, requirementAmount,
            rewardType, rewardRarity, rewardAmount, reputationAmount));
    }

    function getQuestTemplatesCount(uint8 tier) public view returns (uint256) {
        return quests[tier].length;
    }

    function getQuestTemplate(uint8 tier, uint256 index) public view returns (Rarity, RequirementType, Rarity, uint256, RewardType, Rarity, uint256, uint256) {
        Quest memory quest = quests[tier][index];
        return (quest.tier, quest.requirementType, quest.requirementRarity, quest.requirementAmount, quest.rewardType, quest.rewardRarity, quest.rewardAmount, quest.reputationAmount);
    }

    //move element to be deleted at the end, pop it
    function deleteQuest(uint8 tier, uint32 index) public {
        require(index < quests[tier].length, "Index out of bounds");
        quests[tier][index] = quests[tier][quests[tier].length - 1];
        quests[tier].pop();
    }

    function getQuestData(uint256 questID) public view returns (uint256, Rarity, RequirementType, Rarity, uint256, RewardType, Rarity, uint256, uint256) {
        Quest memory quest = questList[questID];
        return (quest.id, quest.tier, quest.requirementType, quest.requirementRarity, quest.requirementAmount,
        quest.rewardType, quest.rewardRarity, quest.rewardAmount, quest.reputationAmount);
    }

    function getCharacterQuestData(uint256 characterID) public view returns (uint256[] memory) {
        uint256[] memory questDataKeys = new uint256[](3);
        questDataKeys[0] = characters.NFTVAR_SIMPLEQUEST_PROGRESS();
        questDataKeys[1] = characters.NFTVAR_SIMPLEQUEST_TYPE();
        questDataKeys[2] = characters.NFTVAR_REPUTATION();
        return characters.getNFTVars(characterID, questDataKeys);
    }

    function getCharacterQuestDataDetails(uint256 characterID) public view returns (uint256[] memory, uint256, Rarity,
        RequirementType, Rarity, uint256,
        RewardType, Rarity, uint256, uint256) {
        if (characterQuest[characterID] == 0) {
            return (getCharacterQuestData(characterID), 0, Rarity.COMMON,
            RequirementType.NONE, Rarity.COMMON, 0,
            RewardType.NONE, Rarity.COMMON, 0, 0);
        }
        Quest memory quest = questList[characterQuest[characterID]];
        return (getCharacterQuestData(characterID),
        quest.id, quest.tier,
        quest.requirementType, quest.requirementRarity, quest.requirementAmount,
        quest.rewardType, quest.rewardRarity, quest.rewardAmount,
        quest.reputationAmount);
    }

    // STEP ONE
    function generateRequestQuestSeed(uint256 characterID) public {
        safeRandoms.requestSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID), false);
    }

    // STEP TWO
    function requestQuest(uint256 characterID) public returns (uint256) {
        assertNotOnQuest(characterID);
        return assignNewQuest(characterID);
    }

    function assignNewQuest(uint256 characterID) private returns (uint256) {
        uint256 seed = safeRandoms.popSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID), true, true);
        uint256 currentReputation = characters.getNftVar(characterID, characters.NFTVAR_REPUTATION());
        uint256 reputationLevel;
        if (currentReputation < vars[VAR_REPUTATION_LEVEL_2]) {
            reputationLevel = 0;
        } else if (currentReputation < vars[VAR_REPUTATION_LEVEL_3]) {
            reputationLevel = 1;
        } else if (currentReputation < vars[VAR_REPUTATION_LEVEL_4]) {
            reputationLevel = 2;
        } else if (currentReputation < vars[VAR_REPUTATION_LEVEL_5]) {
            reputationLevel = 3;
        } else {
            reputationLevel = 4;
        }
        uint256 tierRoll = RandomUtil.randomSeededMinMax(1, 100, seed);
        seed = RandomUtil.combineSeeds(seed,1);
        uint256[4] memory chances = questTierChances[reputationLevel];
        Quest memory quest;
        if (tierRoll > chances[3]) {
            quest = getNewQuest(Rarity.LEGENDARY, seed);
        }
        else if (tierRoll > chances[2]) {
            quest = getNewQuest(Rarity.EPIC, seed);
        }
        else if (tierRoll > chances[1]) {
            quest = getNewQuest(Rarity.RARE, seed);
        }
        else if (tierRoll > chances[0]) {
            quest = getNewQuest(Rarity.UNCOMMON, seed);
        }
        else {
            quest = getNewQuest(Rarity.COMMON, seed);
        }
        characterQuest[characterID] = quest.id;
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), 0);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_TYPE(), uint256(quest.requirementType));
        emit QuestAssigned(quest.id, characterID);
        return quest.id;
    }

    function getNewQuest(Rarity tier, uint256 seed) private returns (Quest memory) {
        uint256 index = RandomUtil.randomSeededMinMax(0, quests[uint8(tier)].length - 1, seed);
        Quest memory quest = quests[vars[uint8(tier)]][index];
        quest.id = nextQuestID++;
        questList[quest.id] = quest;
        return quest;
    }

    function canSkipQuest(uint256 characterID) public view returns (bool) {
        return characters.getStaminaPoints(characterID) >= staminaCost;
    }

    // free for now, later should be restrained and user has to pay stamina or something
    function skipQuest(uint256 characterID) public returns (uint256) {
        require(canSkipQuest(characterID), "Character does not have enough stamina to skip quest");
        characters.getFightDataAndDrainStamina(msg.sender, characterID, staminaCost, true, 0);
        return assignNewQuest(characterID);
    }

    function setSkipQuestStaminaCost(uint8 points) public restricted {
        staminaCost = points;
    }

    function clearQuestData(uint256 characterID) public {
        // clear quest data
        characterQuest[characterID] = 0;
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), 0);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_TYPE(), 0);
    }

    function completeQuest(uint256 characterID) external {
        uint256[] memory questData = getCharacterQuestData(characterID);
        assertOnQuest(characterID);
        assertQuestCompleted(characterID, questData[0]);
        uint256 questID = characterQuest[characterID];
        uint256 currentReputation = questData[2];
        // reward for completing quest
        rewardQuest(questID, characterID);
        characters.setNftVar(characterID, characters.NFTVAR_REPUTATION(), currentReputation + questList[questID].reputationAmount);
        clearQuestData(characterID);
        emit QuestComplete(questID, characterID);
        // after quest competition, assign new quest to the character
        assignNewQuest(characterID);
    }

    function rewardQuest(uint256 questID, uint256 characterID) private {
        Quest memory quest = questList[questID];
        if (quest.rewardType == RewardType.WEAPON) {
            // rewardType = 1
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
        } else if (quest.rewardType == RewardType.TRINKET) {
            for (uint8 i = 0; i < quest.rewardAmount; i++) {
                uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - i - 1))));
                uint256 trinketEffect = (seed / 100) % 5;
                trinket.mint(msg.sender, uint8(quest.rewardRarity), trinketEffect);
            }
        } else if (quest.rewardType == RewardType.SHIELD) {
            for (uint8 i = 0; i < quest.rewardAmount; i++) {
                uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - i - 1))));
                uint256 roll = seed % 100;
                shields.mintShieldWithStars(msg.sender, uint8(quest.rewardRarity), roll);
            }
        } else if (quest.rewardType == RewardType.DUST) {
            uint32[] memory incrementDustSupplies = new uint32[](weapons.getDustSupplies(msg.sender).length);
            incrementDustSupplies[uint256(quest.rewardRarity)] = uint32(quest.rewardAmount);
            weapons.incrementDustSupplies(msg.sender, incrementDustSupplies[0], incrementDustSupplies[1], incrementDustSupplies[2]);
        } else if (quest.rewardType == RewardType.EXPERIENCE) {
            characters.gainXp(characterID, uint16(quest.rewardAmount));
        }
        else {
            revert("Unknown reward type");
        }
    }

    // TODO: Remember to restrict functions, security, kill switch
    function submitProgress(uint256 characterID, uint256[] memory tokenIds) public {
        assertOnQuest(characterID);
        uint256 questID = characterQuest[characterID];
        Quest memory quest = questList[characterQuest[characterID]];
        require(tokenIds.length != 0, "No tokenIds provided");
        if (quest.requirementType == RequirementType.WEAPON) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                if (weapons.ownerOf(tokenID) != msg.sender) {
                    revert("You don't own this weapon");
                }
                if ((weapons.getStars(tokenID)) != uint256(quest.requirementRarity)) {
                    revert("Wrong weapon rarity");
                }
                weapons.burnWithoutDust(tokenID);
                incrementQuestProgress(characterID, questID, 1);
            }
            emit QuestProgressed(questID, characterID);
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
                incrementQuestProgress(characterID, questID, 1);
            }
            emit QuestProgressed(questID, characterID);
        } else if (quest.requirementType == RequirementType.TRINKET) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                if (trinket.ownerOf(tokenID) != msg.sender) {
                    revert("You don't own this trinket");
                }
                if (trinket.getStars(tokenID) != uint256(quest.requirementRarity)) {
                    revert("Wrong trinket rarity");
                }
                trinket.burn(tokenID);
                incrementQuestProgress(characterID, questID, 1);
            }
            emit QuestProgressed(questID, characterID);
        } else if (quest.requirementType == RequirementType.SHIELD) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                if (shields.ownerOf(tokenID) != msg.sender) {
                    revert("You don't own this shield");
                }
                if (shields.getStars(tokenID) != uint256(quest.requirementRarity)) {
                    revert("Wrong shield rarity");
                }
                shields.burn(tokenID);
                incrementQuestProgress(characterID, questID, 1);
            }
            emit QuestProgressed(questID, characterID);
        } else {
            revert("Unknown requirement type");
        }
        // should I automatically complete the quest and assign new one? or should I let user complete quest later
    }

    function submitDustProgress(uint256 characterID, uint32 amount) public {
        assertOnQuest(characterID);
        uint256 questID = characterQuest[characterID];
        uint256[] memory questData = getCharacterQuestData(characterID);
        Quest memory quest = questList[questID];
        require(quest.requirementType == RequirementType.DUST, "Wrong quest type");
        uint32[] memory dustSupplies = weapons.getDustSupplies(msg.sender);
        require(amount <= dustSupplies[uint256(quest.requirementRarity)], "Not enough dust supply");
        uint32[] memory decrementDustSupplies = new uint32[](dustSupplies.length);
        decrementDustSupplies[uint256(quest.requirementRarity)] = amount;
        weapons.decrementDustSupplies(msg.sender, decrementDustSupplies[0], decrementDustSupplies[1], decrementDustSupplies[2]);
        incrementQuestProgress(characterID, questID, amount);
    }

    function incrementQuestProgress(uint256 characterID, uint256 questID, uint256 progress) private {
        uint currentProgress = characters.getNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS());
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), currentProgress + progress);
    }

}
