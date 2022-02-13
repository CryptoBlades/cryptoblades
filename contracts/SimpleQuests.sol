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
import "./BurningManager.sol";

contract SimpleQuests is Initializable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    uint256 internal constant SEED_RANDOM_QUEST = uint(keccak256("SEED_RANDOM_QUEST"));
    uint256 internal constant SEED_REWARD_QUEST = uint(keccak256("SEED_REWARD_QUEST"));

    /* Quest rarities
    *   Quests templates rarities on (0 - common, 1 - uncommon, 2 - rare, 3 - epic, 4 - legendary)
    *   Promo quests arrays are accordingly (10 - common, 11 - uncommon, 12 - rare, 13 - epic, 14 - legendary)
    */

    /* Promo quest templates
    *   Use promo quests flag in order to use promo quest templates, when it's true, it will
    *   use promo quest templates, when it's false, it will use regular quest templates
    */

    Characters public characters;
    Weapons public weapons;
    Junk public junk;
    RaidTrinket public trinket;
    Shields public shields;
    BurningManager public burningManager;
    SafeRandoms public safeRandoms;

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
    uint8 public constant VAR_SKIP_QUEST_STAMINA_COST = 30;
    uint256 internal constant NFTVAR_SIMPLEQUEST_PROGRESS = 101;
    uint256 internal constant NFTVAR_SIMPLEQUEST_TYPE = 102;
    uint256 internal constant NFTVAR_REPUTATION = 103;

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

    enum RequirementType{NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, STAMINA, SOUL, RAID}
    enum RewardType{NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, EXPERIENCE, SOUL}
    enum Rarity{COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

    uint256 public nextQuestID;

    mapping(uint256 => uint256[]) public questTemplates;
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => uint256) public characterQuest;
    mapping(uint256 => uint256[4]) public tierChances;
    mapping(uint256 => uint256) public vars;
    mapping(uint256 => uint256) public lastFreeSkipUsage;

    event QuestAssigned(uint256 indexed questID, uint256 indexed characterID);
    event QuestProgressed(uint256 indexed questID, uint256 indexed characterID);
    event QuestComplete(uint256 indexed questID, uint256 indexed characterID);
    event QuestRewarded(uint256 indexed questID, uint256 indexed characterID, uint256[] rewards);

    function initialize(Characters _characters, Weapons _weapons, Junk _junk, RaidTrinket _trinket, Shields _shields, BurningManager _burningManager, SafeRandoms _safeRandoms) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        characters = _characters;
        weapons = _weapons;
        junk = _junk;
        trinket = _trinket;
        shields = _shields;
        burningManager = _burningManager;
        safeRandoms = _safeRandoms;
        nextQuestID = 1;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NA");
    }

    modifier assertQuestsEnabled() {
        _assertQuestsEnabled();
        _;
    }

    function _assertQuestsEnabled() internal view {
        require(vars[VAR_CONTRACT_ENABLED] == 1, "Quests disabled");
    }

    modifier assertOnQuest(uint256 characterID, bool onQuest) {
        _assertOnQuest(characterID, onQuest);
        _;
    }

    function _assertOnQuest(uint256 characterID, bool onQuest) internal view {
        require((characterQuest[characterID] != 0) == onQuest, "Invalid quest state");
    }

    modifier assertOwnsCharacter(uint256 characterID) {
        _assertOwnsCharacter(characterID);
        _;
    }

    function _assertOwnsCharacter(uint256 characterID) internal view {
        require(characters.ownerOf(characterID) == msg.sender, "Not character owner");
    }

    // FUNCTIONS

    function generateRequestQuestSeed(uint256 characterID) assertQuestsEnabled assertOwnsCharacter(characterID) public {
        safeRandoms.requestSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID));
    }

    function requestQuest(uint256 characterID) public assertQuestsEnabled assertOnQuest(characterID, false) returns (uint256) {
        return assignNewQuest(characterID);
    }

    function assignNewQuest(uint256 characterID) private returns (uint256) {
        uint256 seed = safeRandoms.popSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID), true, true);
        uint256 currentReputation = characters.getNftVar(characterID, NFTVAR_REPUTATION);
        uint256 reputationTier;
        if (currentReputation > vars[VAR_REPUTATION_LEVEL_5]) {
            reputationTier = 4;
        } else if (currentReputation > vars[VAR_REPUTATION_LEVEL_4]) {
            reputationTier = 3;
        } else if (currentReputation > vars[VAR_REPUTATION_LEVEL_3]) {
            reputationTier = 2;
        } else if (currentReputation > vars[VAR_REPUTATION_LEVEL_2]) {
            reputationTier = 1;
        } else {
            reputationTier = 0;
        }
        uint256[4] memory chances = tierChances[reputationTier];
        uint256 tierRoll = RandomUtil.randomSeededMinMax(1, 100, seed);
        seed = RandomUtil.combineSeeds(seed, 1);
        uint256 questID;
        if (tierRoll > chances[3]) {
            questID = generateNewQuest(vars[VAR_LEGENDARY_TIER], seed);
        }
        else if (tierRoll > chances[2]) {
            questID = generateNewQuest(vars[VAR_EPIC_TIER], seed);
        }
        else if (tierRoll > chances[1]) {
            questID = generateNewQuest(vars[VAR_RARE_TIER], seed);
        }
        else if (tierRoll > chances[0]) {
            questID = generateNewQuest(vars[VAR_UNCOMMON_TIER], seed);
        }
        else {
            questID = generateNewQuest(vars[VAR_COMMON_TIER], seed);
        }
        characterQuest[characterID] = questID;
        uint256[] memory fields = new uint256[](2);
        fields[0] = NFTVAR_SIMPLEQUEST_PROGRESS;
        fields[1] = NFTVAR_SIMPLEQUEST_TYPE;
        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = uint256(quests[questID].requirementType);
        characters.setNFTVars(characterID, fields, values);
        emit QuestAssigned(questID, characterID);
        return questID;
    }

    function generateNewQuest(uint256 tier, uint256 seed) private view returns (uint256) {
        uint256[] memory tierQuestTemplates = questTemplates[tier];
        uint256 index = RandomUtil.randomSeededMinMax(0, tierQuestTemplates.length - 1, seed);
        return tierQuestTemplates[index];
    }

    function skipQuest(uint256 characterID) public assertQuestsEnabled returns (uint256) {
        if(hasFreeSkip(characterID)) {
            lastFreeSkipUsage[characterID] = now;
        } else {
            characters.getFightDataAndDrainStamina(msg.sender, characterID, uint8(vars[VAR_SKIP_QUEST_STAMINA_COST]), false, 0);
        }

        return assignNewQuest(characterID);
    }

    function completeQuest(uint256 characterID) public assertQuestsEnabled assertOnQuest(characterID, true) returns (uint256[] memory questRewards) {
        uint256[] memory questData = getCharacterQuestData(characterID);
        require(questData[0] >= quests[characterQuest[characterID]].requirementAmount, "Not completed");
        uint256 questID = characterQuest[characterID];
        uint256 currentReputation = questData[2];
        questRewards = rewardQuest(questID, characterID);
        emit QuestRewarded(questID, characterID, questRewards);
        characters.setNftVar(characterID, NFTVAR_REPUTATION, currentReputation + quests[questID].reputationAmount);
        emit QuestComplete(questID, characterID);
        assignNewQuest(characterID);
    }

    function generateRewardQuestSeed(uint256 characterID) assertQuestsEnabled assertOwnsCharacter(characterID) public {
        safeRandoms.requestSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_REWARD_QUEST, characterID));
    }

    function rewardQuest(uint256 questID, uint256 characterID) private returns (uint256[] memory) {
        uint256 seed = safeRandoms.popSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_REWARD_QUEST, characterID), true, false);
        Quest memory quest = quests[questID];
        if (quest.rewardType == RewardType.WEAPON) {
            uint256[] memory tokenIDs = new uint256[](quest.rewardAmount);
            for (uint8 i = 0; i < quest.rewardAmount; i++) {
                tokenIDs[i] = weapons.mintWeaponWithStars(characters.ownerOf(characterID), uint256(quest.rewardRarity), seed, 100);
                seed = RandomUtil.combineSeeds(seed, i);
            }
            return tokenIDs;
        } else if (quest.rewardType == RewardType.JUNK) {
            return junk.mintN(msg.sender, uint8(quest.rewardRarity), uint32(quest.rewardAmount));
        } else if (quest.rewardType == RewardType.TRINKET) {
            return trinket.mintN(msg.sender, uint8(quest.rewardRarity), uint32(quest.rewardAmount), seed);
        } else if (quest.rewardType == RewardType.SHIELD) {
            //0 is NORMAL SHIELD TYPE
            return shields.mintShieldsWithStars(msg.sender, uint8(quest.rewardRarity), 0, uint32(quest.rewardAmount), seed);
        } else if (quest.rewardType == RewardType.DUST) {
            uint32[] memory incrementDustSupplies = new uint32[](3);
            incrementDustSupplies[uint256(quest.rewardRarity)] = uint32(quest.rewardAmount);
            weapons.incrementDustSupplies(msg.sender, incrementDustSupplies[0], incrementDustSupplies[1], incrementDustSupplies[2]);
        } else if (quest.rewardType == RewardType.EXPERIENCE) {
            characters.gainXp(characterID, uint16(quest.rewardAmount));
        } else if (quest.rewardType == RewardType.SOUL) {
            burningManager.giveawaySoul(msg.sender, quest.rewardAmount);
        }
        else {
            revert("Unknown reward type");
        }
        return new uint256[](0);
    }

    // SUBMITTING PROGRESS

    function submitProgress(uint256 characterID, uint256[] memory tokenIds) public assertQuestsEnabled assertOnQuest(characterID, true) {
        require(tokenIds.length != 0, "No tokenIds");
        uint256 questID = characterQuest[characterID];
        Quest memory quest = quests[questID];
        if (quest.requirementType == RequirementType.WEAPON) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(weapons.ownerOf(tokenID) == msg.sender, "Not weapon owner");
                require(weapons.getStars(tokenID) == uint256(quest.requirementRarity), "Wrong weapon rarity");
            }
            weapons.burnWithoutDust(tokenIds);
            incrementQuestProgress(characterID, questID, tokenIds.length);
        } else if (quest.requirementType == RequirementType.JUNK) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(junk.ownerOf(tokenID) == msg.sender, "Not junk owner");
                require(junk.tokenStars(tokenID) == uint256(quest.requirementRarity), "Wrong junk rarity");
            }
            junk.burn(tokenIds);
            incrementQuestProgress(characterID, questID, tokenIds.length);
        } else if (quest.requirementType == RequirementType.TRINKET) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(trinket.ownerOf(tokenID) == msg.sender, "Not trinket owner");
                require(trinket.tokenStars(tokenID) == uint256(quest.requirementRarity), "Wrong trinket rarity");
            }
            trinket.burn(tokenIds);
            incrementQuestProgress(characterID, questID, tokenIds.length);
        } else if (quest.requirementType == RequirementType.SHIELD) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(shields.ownerOf(tokenID) == msg.sender, "Not shield owner");
                require(shields.getStars(tokenID) == uint256(quest.requirementRarity), "Wrong shield rarity");
            }
            shields.burn(tokenIds);
            incrementQuestProgress(characterID, questID, tokenIds.length);
        } else {
            revert("Unknown requirement type");
        }
    }

    function submitProgressAmount(uint256 characterID, uint8 amount) public assertQuestsEnabled assertOnQuest(characterID, true) {
        uint256 questID = characterQuest[characterID];
        Quest memory quest = quests[questID];
        if (quest.requirementType == RequirementType.STAMINA) {
            characters.getFightDataAndDrainStamina(msg.sender, characterID, amount, false, 0);
            incrementQuestProgress(characterID, questID, amount);
        } else if (quest.requirementType == RequirementType.DUST) {
            uint32[] memory decrementDustSupplies = new uint32[](3);
            decrementDustSupplies[uint256(quest.requirementRarity)] = amount;
            weapons.decrementDustSupplies(msg.sender, decrementDustSupplies[0], decrementDustSupplies[1], decrementDustSupplies[2]);
            incrementQuestProgress(characterID, questID, amount);
        } else if (quest.requirementType == RequirementType.SOUL) {
            burningManager.burnSoul(msg.sender, amount);
            incrementQuestProgress(characterID, questID, amount);
        } else {
            revert("Unknown requirement type");
        }
    }

    function incrementQuestProgress(uint256 characterID, uint256 questID, uint256 progress) private {
        uint currentProgress = characters.getNftVar(characterID, NFTVAR_SIMPLEQUEST_PROGRESS);
        characters.setNftVar(characterID, NFTVAR_SIMPLEQUEST_PROGRESS, currentProgress + progress);
        emit QuestProgressed(questID, characterID);
    }

    // VIEWS

    function hasRandomQuestSeedRequested(uint256 characterID) public view returns (bool) {
        return safeRandoms.hasSingleSeedRequest(msg.sender, RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID));
    }

    function hasRandomQuestRewardSeedRequested(uint256 characterID) public view returns (bool) {
        return safeRandoms.hasSingleSeedRequest(msg.sender, RandomUtil.combineSeeds(SEED_REWARD_QUEST, characterID));
    }

    function getVars(uint256[] calldata varFields) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](varFields.length);
        for (uint i = 0; i < varFields.length; i++) {
            result[i] = vars[varFields[i]];
        }
        return result;
    }

    function getTierChances(uint256 reputationLevel) external view returns (uint256[4] memory) {
        return tierChances[reputationLevel];
    }

    function getQuestTemplates(uint8 tier) public view returns (uint256[] memory) {
        return questTemplates[tier];
    }

    function getQuestData(uint256 questID) public view returns (uint256, Rarity, RequirementType, Rarity, uint256, RewardType, Rarity, uint256, uint256) {
        Quest memory quest = quests[questID];
        return (quest.id, quest.tier, quest.requirementType, quest.requirementRarity, quest.requirementAmount,
        quest.rewardType, quest.rewardRarity, quest.rewardAmount, quest.reputationAmount);
    }

    function getCharacterQuestData(uint256 characterID) public view returns (uint256[] memory) {
        uint256[] memory questDataKeys = new uint256[](3);
        questDataKeys[0] = NFTVAR_SIMPLEQUEST_PROGRESS;
        questDataKeys[1] = NFTVAR_SIMPLEQUEST_TYPE;
        questDataKeys[2] = NFTVAR_REPUTATION;
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
        Quest memory quest = quests[characterQuest[characterID]];
        return (getCharacterQuestData(characterID),
        quest.id, quest.tier,
        quest.requirementType, quest.requirementRarity, quest.requirementAmount,
        quest.rewardType, quest.rewardRarity, quest.rewardAmount,
        quest.reputationAmount);
    }

    function canSkipQuest(uint256 characterID) public view returns (bool) {
        return characters.getStaminaPoints(characterID) >= vars[VAR_SKIP_QUEST_STAMINA_COST];
    }

    function hasFreeSkip(uint256 characterID) public view returns (bool) {
        return now / 1 days > lastFreeSkipUsage[characterID] / 1 days;
    }

    function nextFreeSkip() public view returns (uint256) {
        return now + 1 days - now % 1 days;
    }

    // ADMIN

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for (uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    function setTierChances(uint256 tier, uint256[4] memory chances) public restricted {
        tierChances[tier] = chances;
    }

    function addNewQuestTemplate(Rarity tier, RequirementType requirementType, Rarity requirementRarity, uint256 requirementAmount,
        RewardType rewardType, Rarity rewardRarity, uint256 rewardAmount, uint256 reputationAmount) public restricted {
        uint256 questID = addNewQuest(tier, requirementType, requirementRarity, requirementAmount, rewardType, rewardRarity, rewardAmount, reputationAmount);
        questTemplates[uint8(tier)].push(questID);
    }

    function addNewPromoQuestTemplate(Rarity tier, RequirementType requirementType, Rarity requirementRarity, uint256 requirementAmount,
        RewardType rewardType, Rarity rewardRarity, uint256 rewardAmount, uint256 reputationAmount) public restricted {
        uint256 questID = addNewQuest(tier, requirementType, requirementRarity, requirementAmount, rewardType, rewardRarity, rewardAmount, reputationAmount);
        questTemplates[uint8(tier) + 10].push(questID);
    }

    function addNewQuest(Rarity tier, RequirementType requirementType, Rarity requirementRarity, uint256 requirementAmount,
        RewardType rewardType, Rarity rewardRarity, uint256 rewardAmount, uint256 reputationAmount) internal returns (uint256 questID) {
        questID = nextQuestID++;
        quests[questID] = Quest(questID, tier,
            requirementType, requirementRarity, requirementAmount,
            rewardType, rewardRarity, rewardAmount, reputationAmount);
    }

    function deleteQuestTemplate(uint8 tier, uint32 index) public restricted {
        require(index < questTemplates[tier].length, "Index out of bounds");
        questTemplates[tier][index] = questTemplates[tier][questTemplates[tier].length - 1];
        questTemplates[tier].pop();
    }
}
