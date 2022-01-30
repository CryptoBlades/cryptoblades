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

    /* Quest rarities
    *   Quests templates rarities on (0 - common, 1 - uncommon, 2 - rare, 3 - epic, 4 - legendary)
    *   Promo quests arrays are accordingly (10 - common, 11 - uncommon, 12 - rare, 13 - epic, 14 - legendary)
    */

    /* Promo quest templates
    *   Use setUsePromoQuests(bool usePromoQuests) in order to use promo quest templates, when it's true, it will
    *   use promo quest templates, when it's false, it will use regular quest templates
    */

    Characters public characters;
    Weapons public weapons;
    Junk public junk;
    RaidTrinket public trinket;
    Shields public shields;
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

    mapping(uint256 => Quest[]) public questTemplates;
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => uint256) public characterQuest;
    mapping(uint256 => uint256[4]) public tierChances;
    mapping(uint256 => uint256) public vars;

    uint8 public skipQuestStaminaCost;
    uint256 public nextQuestID;
    bool public usePromoQuests;

    event QuestAssigned(uint256 indexed questID, uint256 indexed characterID);
    event QuestProgressed(uint256 indexed questID, uint256 indexed characterID);
    event QuestComplete(uint256 indexed questID, uint256 indexed characterID);

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
        // TODO: What should be the initial values here?
        tierChances[0] = [100, 100, 100, 100];
        tierChances[1] = [85, 100, 100, 100];
        tierChances[2] = [77, 97, 100, 100];
        tierChances[3] = [69, 94, 100, 100];
        tierChances[4] = [66, 93, 99, 100];
        skipQuestStaminaCost = 40;
        nextQuestID = 1;
        usePromoQuests = false;
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "NA");
        _;
    }

    modifier assertQuestsEnabled() {
        require(vars[VAR_CONTRACT_ENABLED] == 1, "Quests are disabled");
        _;
    }

    modifier assertOnQuest(uint256 characterID) {
        require(characterQuest[characterID] != 0, "Not on quest");
        _;
    }

    modifier assertNotOnQuest(uint256 characterID) {
        require(characterQuest[characterID] == 0, "Already on quest");
        _;
    }

    modifier assertOwnsCharacter(uint256 characterID) {
        require(characters.ownerOf(characterID) == msg.sender, "Not character owner");
        _;
    }

    // FUNCTIONS

    function generateRequestQuestSeed(uint256 characterID) assertQuestsEnabled assertOwnsCharacter(characterID) public {
        safeRandoms.requestSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID));
    }

    function requestQuest(uint256 characterID) public assertQuestsEnabled assertNotOnQuest(characterID) returns (uint256) {
        return assignNewQuest(characterID);
    }

    function assignNewQuest(uint256 characterID) private returns (uint256) {
        uint256 seed = safeRandoms.popSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID), true, true);
        uint256 currentReputation = characters.getNftVar(characterID, characters.NFTVAR_REPUTATION());
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
        Quest memory quest;
        if (tierRoll > chances[3]) {
            quest = generateNewQuest(vars[VAR_LEGENDARY_TIER], seed);
        }
        else if (tierRoll > chances[2]) {
            quest = generateNewQuest(vars[VAR_EPIC_TIER], seed);
        }
        else if (tierRoll > chances[1]) {
            quest = generateNewQuest(vars[VAR_RARE_TIER], seed);
        }
        else if (tierRoll > chances[0]) {
            quest = generateNewQuest(vars[VAR_UNCOMMON_TIER], seed);
        }
        else {
            quest = generateNewQuest(vars[VAR_COMMON_TIER], seed);
        }
        characterQuest[characterID] = quest.id;
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), 0);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_TYPE(), uint256(quest.requirementType));
        emit QuestAssigned(quest.id, characterID);
        return quest.id;
    }

    function generateNewQuest(uint256 tier, uint256 seed) private returns (Quest memory) {
        Quest[] memory tierQuestTemplates = questTemplates[tier];
        uint256 index = RandomUtil.randomSeededMinMax(0, tierQuestTemplates.length - 1, seed);
        Quest memory quest = tierQuestTemplates[index];
        quest.id = nextQuestID++;
        quests[quest.id] = quest;
        return quest;
    }

    function skipQuest(uint256 characterID) public assertQuestsEnabled assertOwnsCharacter(characterID) returns (uint256) {
        require(canSkipQuest(characterID), "Character does not have enough stamina to skip quest");
        characters.getFightDataAndDrainStamina(msg.sender, characterID, skipQuestStaminaCost, true, 0);
        return assignNewQuest(characterID);
    }

    function completeQuest(uint256 characterID) public assertQuestsEnabled assertOnQuest(characterID) {
        uint256[] memory questData = getCharacterQuestData(characterID);
        require(questData[0] >= quests[characterQuest[characterID]].requirementAmount, "Not completed");
        uint256 questID = characterQuest[characterID];
        uint256 currentReputation = questData[2];
        rewardQuest(questID, characterID);
        characters.setNftVar(characterID, characters.NFTVAR_REPUTATION(), currentReputation + quests[questID].reputationAmount);
        clearQuestData(characterID);
        emit QuestComplete(questID, characterID);
        assignNewQuest(characterID);
    }

    function clearQuestData(uint256 characterID) private {
        characterQuest[characterID] = 0;
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), 0);
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_TYPE(), 0);
    }

    function rewardQuest(uint256 questID, uint256 characterID) private {
        Quest memory quest = quests[questID];
        if (quest.rewardType == RewardType.WEAPON) {
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
                //NORMAL TYPE
                shields.mintShieldWithStars(msg.sender, uint8(quest.rewardRarity), 0, roll);
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

    // SUBMITTING PROGRESS

    function submitProgress(uint256 characterID, uint256[] memory tokenIds) public assertQuestsEnabled assertOnQuest(characterID) {
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
            emit QuestProgressed(questID, characterID);
        } else if (quest.requirementType == RequirementType.JUNK) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(junk.ownerOf(tokenID) == msg.sender, "Not junk owner");
                require(junk.tokenStars(tokenID) == uint256(quest.requirementRarity), "Wrong junk rarity");
            }
            junk.burn(tokenIds);
            incrementQuestProgress(characterID, questID, tokenIds.length);
            emit QuestProgressed(questID, characterID);
        } else if (quest.requirementType == RequirementType.TRINKET) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(trinket.ownerOf(tokenID) == msg.sender, "Not trinket owner");
                require(trinket.tokenStars(tokenID) == uint256(quest.requirementRarity), "Wrong trinket rarity");
            }
            trinket.burn(tokenIds);
            incrementQuestProgress(characterID, questID, tokenIds.length);
            emit QuestProgressed(questID, characterID);
        } else if (quest.requirementType == RequirementType.SHIELD) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(shields.ownerOf(tokenID) == msg.sender, "Not shield owner");
                require(shields.getStars(tokenID) == uint256(quest.requirementRarity), "Wrong shield rarity");
            }
            shields.burn(tokenIds);
            incrementQuestProgress(characterID, questID, tokenIds.length);
            emit QuestProgressed(questID, characterID);
        } else {
            revert("Unknown requirement type");
        }
    }

    function submitDustProgress(uint256 characterID, uint32 amount) public assertQuestsEnabled assertOnQuest(characterID) {
        uint256 questID = characterQuest[characterID];
        uint256[] memory questData = getCharacterQuestData(characterID);
        Quest memory quest = quests[questID];
        require(quest.requirementType == RequirementType.DUST, "Wrong type");
        uint32[] memory dustSupplies = weapons.getDustSupplies(msg.sender);
        require(amount <= dustSupplies[uint256(quest.requirementRarity)], "Not enough dust");
        uint32[] memory decrementDustSupplies = new uint32[](dustSupplies.length);
        decrementDustSupplies[uint256(quest.requirementRarity)] = amount;
        weapons.decrementDustSupplies(msg.sender, decrementDustSupplies[0], decrementDustSupplies[1], decrementDustSupplies[2]);
        incrementQuestProgress(characterID, questID, amount);
    }

    function incrementQuestProgress(uint256 characterID, uint256 questID, uint256 progress) private {
        uint currentProgress = characters.getNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS());
        characters.setNftVar(characterID, characters.NFTVAR_SIMPLEQUEST_PROGRESS(), currentProgress + progress);
    }

    // VIEWS

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

    function getQuestTemplatesCount(uint8 tier) public view returns (uint256) {
        return questTemplates[tier].length;
    }

    function getQuestData(uint256 questID) public view returns (uint256, Rarity, RequirementType, Rarity, uint256, RewardType, Rarity, uint256, uint256) {
        Quest memory quest = quests[questID];
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
        Quest memory quest = quests[characterQuest[characterID]];
        return (getCharacterQuestData(characterID),
        quest.id, quest.tier,
        quest.requirementType, quest.requirementRarity, quest.requirementAmount,
        quest.rewardType, quest.rewardRarity, quest.rewardAmount,
        quest.reputationAmount);
    }

    function canSkipQuest(uint256 characterID) public view returns (bool) {
        return characters.getStaminaPoints(characterID) >= skipQuestStaminaCost;
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

    function setSkipQuestStaminaCost(uint8 stamina) public restricted {
        skipQuestStaminaCost = stamina;
    }

    function toggleUsePromoQuests() public restricted {
        usePromoQuests = !usePromoQuests;
        if (usePromoQuests) {
            vars[VAR_COMMON_TIER] = 10;
            vars[VAR_UNCOMMON_TIER] = 11;
            vars[VAR_RARE_TIER] = 12;
            vars[VAR_EPIC_TIER] = 13;
            vars[VAR_LEGENDARY_TIER] = 14;
        } else {
            vars[VAR_COMMON_TIER] = 0;
            vars[VAR_UNCOMMON_TIER] = 1;
            vars[VAR_RARE_TIER] = 2;
            vars[VAR_EPIC_TIER] = 3;
            vars[VAR_LEGENDARY_TIER] = 4;
        }
    }

    function addNewQuestTemplate(Rarity tier, RequirementType requirementType, Rarity requirementRarity, uint256 requirementAmount,
        RewardType rewardType, Rarity rewardRarity, uint256 rewardAmount, uint256 reputationAmount) public restricted {
        questTemplates[uint8(tier)].push(Quest(0, tier,
            requirementType, requirementRarity, requirementAmount,
            rewardType, rewardRarity, rewardAmount, reputationAmount));
    }

    function addNewPromoQuestTemplate(Rarity tier, RequirementType requirementType, Rarity requirementRarity, uint256 requirementAmount,
        RewardType rewardType, Rarity rewardRarity, uint256 rewardAmount, uint256 reputationAmount) public restricted {
        questTemplates[uint8(tier) + 10].push(Quest(0, tier,
            requirementType, requirementRarity, requirementAmount,
            rewardType, rewardRarity, rewardAmount, reputationAmount));
    }

    function deleteQuestTemplate(uint8 tier, uint32 index) public restricted {
        require(index < questTemplates[tier].length, "Index out of bounds");
        questTemplates[tier][index] = questTemplates[tier][questTemplates[tier].length - 1];
        questTemplates[tier].pop();
    }
}
