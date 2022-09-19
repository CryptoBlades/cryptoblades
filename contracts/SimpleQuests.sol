pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
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
import "./PartnerVault.sol";

contract SimpleQuests is Initializable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using SafeMath for uint256;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    uint256 internal constant SEED_RANDOM_QUEST = uint(keccak256("SEED_RANDOM_QUEST"));
    uint256 internal constant SEED_REWARD_QUEST = uint(keccak256("SEED_REWARD_QUEST"));
    uint256 internal constant SEED_REWARD_WALLET_QUEST = uint(keccak256("SEED_REWARD_WALLET_QUEST"));
    uint256 internal constant SEED_REWARD_WEEKLY = uint(keccak256("SEED_REWARD_WEEKLY"));

    /* Quest rarities
    *   Quests templates rarities on (0 - common, 1 - uncommon, 2 - rare, 3 - epic, 4 - legendary)
    *   Promo quests arrays are accordingly (10 - common, 11 - uncommon, 12 - rare, 13 - epic, 14 - legendary)
    *   Pickable quests on 20
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
    PartnerVault public partnerVault;

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
//    uint8 public constant VAR_WEEKLY_COMPLETIONS_GOAL = 31;
    uint256 internal constant NFTVAR_SIMPLEQUEST_PROGRESS = 101;
    uint256 internal constant NFTVAR_SIMPLEQUEST_TYPE = 102;
    uint256 internal constant NFTVAR_REPUTATION = 103;

    struct Quest {
        uint256 id;
        Rarity tier;
        ItemType requirementType;
        uint256 requirementRarity;
        uint256 requirementAmount;
        address requirementExternalAddress;
        ItemType rewardType;
        uint256 rewardRarity;
        uint256 rewardAmount;
        address rewardExternalAddress;
        uint256 reputationAmount;
    }

    struct Reward {
        uint256 id;
        ItemType rewardType;
        uint256 rewardRarity;
        uint256 rewardAmount;
        address rewardExternalAddress;
        uint256 reputationAmount;
    }

    enum ItemType{NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, STAMINA, SOUL, RAID, EXPERIENCE, EXTERNAL, EXTERNAL_HOLD, CHARACTER}
    enum Rarity{COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

    uint256 public nextQuestID;
    uint256 public nextRewardID;

    mapping(uint256 => uint256[]) public questTemplates;
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => uint256) public questSupplies;
    mapping(uint256 => uint256) public questDeadlines;
    mapping(uint256 => uint256) public questIndexes;
    mapping(uint256 => uint256) public characterQuest;
    mapping(uint256 => uint256[4]) public tierChances;
    mapping(uint256 => uint256) public vars;
    mapping(uint256 => uint256) public lastFreeSkipUsage;
    mapping(address => mapping(uint256 => uint256)) public weeklyCompletions; //user to week to completions
    mapping(address => mapping(uint256 => bool)) public weeklyRewardClaimed;
    mapping(uint256 => Reward) public rewards;
    mapping(uint256 => uint256) private weeklyRewards; //unused
    mapping(uint256 => uint256) public weeklyCompletionsGoal;
    mapping(address => mapping(uint256 => uint256)) public walletQuestProgress; // wallet, questID, progress
    uint constant maxWeeksInAYear = 53;
    uint constant pickableTier = 20;
    uint constant walletTier = 30;

    event QuestAssigned(uint256 indexed questID, uint256 indexed characterID);
    event QuestProgressed(uint256 indexed questID, uint256 indexed characterID);
    event QuestComplete(uint256 indexed questID, uint256 indexed characterID);
    event QuestRewarded(uint256 indexed questID, uint256 indexed characterID, uint256[] rewards);
    event QuestSkipped(uint256 indexed questID, uint256 indexed characterID);
    event WeeklyRewardClaimed(address user, uint256 indexed rewardID, uint256[] rewards);
    event RewardAdded(uint256 indexed rewardID);
    event WeeklyRewardSet(uint256 indexed rewardID, uint256 indexed week);
    event WalletQuestProgressed(uint256 indexed questID, address indexed wallet);
    event WalletQuestComplete(uint256 indexed questID, address indexed wallet);
    event WalletQuestRewarded(uint256 indexed questID, address indexed wallet, uint256[] rewards);

    function initialize(Characters _characters, Weapons _weapons, Junk _junk, RaidTrinket _trinket, Shields _shields, BurningManager _burningManager, SafeRandoms _safeRandoms, PartnerVault _partnerVault) public initializer {
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
        partnerVault = _partnerVault;
        nextQuestID = 1;
        nextRewardID = 1;
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

    modifier assertCanClaimWeeklyReward(address user) {
        _assertCanClaimWeeklyReward(user);
        _;
    }

    function _assertCanClaimWeeklyReward(address user) internal view {
        require(weeklyRewardClaimed[user][now / 1 weeks] == false, "Reward already claimed");
        require(getWeeklyCompletions(user) >= weeklyCompletionsGoal[getWeekNumber()], "Not enough weekly completions");
    }

    // FUNCTIONS

    function generateRequestQuestSeed(uint256 characterID) assertQuestsEnabled assertOwnsCharacter(characterID) public {
        safeRandoms.requestSingleSeed(address(this), RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID));
    }

    function requestQuest(uint256 characterID) public assertQuestsEnabled assertOnQuest(characterID, false) returns (uint256) {
        return assignNewQuest(characterID);
    }

    function requestPickableQuest(uint256 characterID, uint256 questID) public assertQuestsEnabled assertOwnsCharacter(characterID) assertOnQuest(characterID, false) returns (uint256) {
        require(questID == questTemplates[pickableTier][questIndexes[questID]]); // pickable quest tier check
        return setCharacterQuest(characterID, pickableTier, questTemplates[pickableTier][questIndexes[questID]]);
    }

    function assignNewQuest(uint256 characterID) private returns (uint256) {
        uint256 seed = safeRandoms.popSingleSeed(address(this), RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID), true, true);
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

        uint256 tier;
        if (tierRoll > chances[3]) {
            tier = vars[VAR_LEGENDARY_TIER];
        }
        else if (tierRoll > chances[2]) {
            tier = vars[VAR_EPIC_TIER];
        }
        else if (tierRoll > chances[1]) {
            tier = vars[VAR_RARE_TIER];
        }
        else if (tierRoll > chances[0]) {
            tier = vars[VAR_UNCOMMON_TIER];
        }
        else {
            tier = vars[VAR_COMMON_TIER];
        }
        uint256 questID = generateNewQuest(tier, seed);
        return setCharacterQuest(characterID, tier, questID);
    }

    function setCharacterQuest(uint256 characterID, uint256 tier, uint256 questID) private returns (uint256) {
        decrementQuestSupply(tier, questID);
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

    function decrementQuestSupply(uint256 tier, uint256 questID) private {
        if (questSupplies[questID] > 0) {
            questSupplies[questID]--;
            if (questSupplies[questID] == 0) {
                deleteQuestTemplate(tier, questID);
            }
        }
    }

    function generateNewQuest(uint256 tier, uint256 seed) private view returns (uint256) {
        uint256[] memory tierQuestTemplates = questTemplates[tier];
        uint256 index = RandomUtil.randomSeededMinMax(0, tierQuestTemplates.length - 1, seed);
        return tierQuestTemplates[index];
    }

    function skipQuest(uint256 characterID) public returns (uint256) {
        return skipQuest(characterID, 0);
    }

    function skipQuest(uint256 characterID, uint256 pickedQuestID) public assertQuestsEnabled assertOnQuest(characterID, true) assertOwnsCharacter(characterID) returns (uint256) {
        if (hasFreeSkip(characterID)) {
            lastFreeSkipUsage[characterID] = now;
        } else {
            characters.getFightDataAndDrainStamina(msg.sender, characterID, uint8(vars[VAR_SKIP_QUEST_STAMINA_COST]), false, 0);
        }
        emit QuestSkipped(characterQuest[characterID], characterID);
        return _assignNextQuest(characterID, pickedQuestID);
    }

    function completeQuest(uint256 characterID) public returns (uint256[] memory questRewards) {
        return completeQuest(characterID, 0);
    }

    function completeQuest(uint256 characterID, uint256 pickedQuestID) public assertQuestsEnabled assertOwnsCharacter(characterID) assertOnQuest(characterID, true) returns (uint256[] memory questRewards) {
        uint256[] memory questData = getCharacterQuestData(characterID);
        require(questData[0] >= quests[characterQuest[characterID]].requirementAmount, "Not completed");
        uint256 questID = characterQuest[characterID];
        require(questDeadlines[questID] == 0 || questDeadlines[questID] >= now, "Quest deadline has passed");
        uint256 currentReputation = questData[2];
        questRewards = rewardCharacterQuest(questID, characterID);
        emit QuestRewarded(questID, characterID, questRewards);
        characters.setNftVar(characterID, NFTVAR_REPUTATION, currentReputation + quests[questID].reputationAmount);
        emit QuestComplete(questID, characterID);
        weeklyCompletions[msg.sender][now / 1 weeks] += 1;
        _assignNextQuest(characterID, pickedQuestID);
    }

    function completeWalletQuest(uint256 questID) public assertQuestsEnabled returns (uint256[] memory questRewards) {
        require(walletQuestProgress[msg.sender][questID] >= quests[questID].requirementAmount, "Not completed");
        require(questDeadlines[questID] == 0 || questDeadlines[questID] >= now, "Quest deadline has passed");
        questRewards = rewardWalletQuest(questID);
        emit WalletQuestRewarded(questID, msg.sender, questRewards);
        emit WalletQuestComplete(questID, msg.sender);
        weeklyCompletions[msg.sender][now / 1 weeks] += 1;
        walletQuestProgress[msg.sender][questID] = 0;
        decrementQuestSupply(walletTier, questID);
    }

    function _assignNextQuest(uint256 characterID, uint256 pickedQuestID) internal returns (uint256) {
        if(pickedQuestID == 0) // random quest
            return assignNewQuest(characterID);
        else {
            require(pickedQuestID == questTemplates[pickableTier][questIndexes[pickedQuestID]]); // pickable quest tier check
            return setCharacterQuest(characterID, pickableTier, pickedQuestID);
        }
    }

    function generateRewardQuestSeed(uint256 characterID) assertQuestsEnabled assertOwnsCharacter(characterID) assertOnQuest(characterID, true) public {
        uint256[] memory questData = getCharacterQuestData(characterID);
        require(questData[0] >= quests[characterQuest[characterID]].requirementAmount);
        _generateRewardQuestSeed(characterID, false);
    }

    function _generateRewardQuestSeed(uint256 characterID, bool forced) internal {
        safeRandoms.requestSingleSeed(address(this), RandomUtil.combineSeeds(SEED_REWARD_QUEST, characterID), forced);
    }

    function _generateRewardWalletQuestSeed(uint256 questID, bool forced) internal {
        safeRandoms.requestSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_REWARD_WALLET_QUEST, questID), forced);
    }

    function rewardCharacterQuest(uint256 questID, uint256 characterID) private returns (uint256[] memory) {
        uint256 seed = safeRandoms.popSingleSeed(address(this), RandomUtil.combineSeeds(SEED_REWARD_QUEST, characterID), true, false);
        return rewardQuest(getQuestReward(quests[questID]), characterID, seed);
    }

    function rewardWalletQuest(uint256 questID) private returns (uint256[] memory) {
        uint256 seed = safeRandoms.popSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_REWARD_WALLET_QUEST, questID), true, false);
        return rewardQuest(getQuestReward(quests[questID]), SEED_REWARD_WALLET_QUEST/*hack number to avoid bumping 0 accidentally*/, seed);
    }

    function rewardQuest(Reward memory reward, uint256 characterID, uint256 seed) private returns (uint256[] memory) {
        //reward.id is questID for quests and weekNumber for weekly rewards!
        if (reward.rewardType == ItemType.WEAPON) {
            uint256[] memory tokenIDs = new uint256[](reward.rewardAmount);
            for (uint8 i = 0; i < reward.rewardAmount; i++) {
                tokenIDs[i] = weapons.mintWeaponWithStars(msg.sender, reward.rewardRarity, seed, 100);
                seed = RandomUtil.combineSeeds(seed, i);
            }
            return tokenIDs;
        } else if (reward.rewardType == ItemType.JUNK) {
            return junk.mintN(msg.sender, uint8(reward.rewardRarity), uint32(reward.rewardAmount));
        } else if (reward.rewardType == ItemType.TRINKET) {
            return trinket.mintN(msg.sender, uint8(reward.rewardRarity), uint32(reward.rewardAmount), seed);
        } else if (reward.rewardType == ItemType.SHIELD) {
            //0 is NORMAL SHIELD TYPE
            return shields.mintShieldsWithStars(msg.sender, uint8(reward.rewardRarity), 0, uint32(reward.rewardAmount), seed);
        } else if (reward.rewardType == ItemType.DUST) {
            uint32[] memory incrementDustSupplies = new uint32[](3);
            incrementDustSupplies[uint256(reward.rewardRarity)] = uint32(reward.rewardAmount);
            weapons.incrementDustSupplies(msg.sender, incrementDustSupplies[0], incrementDustSupplies[1], incrementDustSupplies[2]);
        } else if (reward.rewardType == ItemType.EXPERIENCE) {
            characters.gainXp(characterID, uint16(reward.rewardAmount));
        } else if (reward.rewardType == ItemType.SOUL) {
            burningManager.giveAwaySoul(msg.sender, reward.rewardAmount);
        } else if (reward.rewardType == ItemType.EXTERNAL) {
            partnerVault.transferReward(reward.rewardExternalAddress, msg.sender, reward.rewardAmount, seed);
        } else if (reward.rewardType == ItemType.CHARACTER) {
            for (uint8 i = 0; i < reward.rewardAmount; i++) {
                characters.mint(msg.sender, seed);
                seed = RandomUtil.combineSeeds(seed, i);
            }
        }
        else {
            revert("Unknown reward type");
        }
        return new uint256[](0);
    }

    function generateRewardWeeklySeed(uint256 rewardID) assertQuestsEnabled assertCanClaimWeeklyReward(msg.sender) public {
        safeRandoms.requestSingleSeed(msg.sender, RandomUtil.combineSeeds(SEED_REWARD_WEEKLY, rewardID));
    }

    function claimWeeklyReward() assertQuestsEnabled assertCanClaimWeeklyReward(msg.sender) public returns (uint256[] memory weeklyRewardIDs) {
        uint256 rewardID = getWeekNumber();
        weeklyRewardIDs = rewardWeekly(rewardID);
        weeklyRewardClaimed[msg.sender][now / 1 weeks] = true;
        emit WeeklyRewardClaimed(msg.sender, rewardID, weeklyRewardIDs);
    }

    function rewardWeekly(uint256 rewardID) private returns (uint256[] memory) {
        uint256 seed = safeRandoms.popSingleSeed(tx.origin, RandomUtil.combineSeeds(SEED_REWARD_WEEKLY, rewardID), true, true);
        return rewardQuest(rewards[rewardID], SEED_REWARD_WEEKLY/*hack number to avoid bumping 0 accidentally*/, seed);
    }

    // SUBMITTING PROGRESS

    function submitProgress(uint256 characterID, uint256[] memory tokenIds) public assertOnQuest(characterID, true) {
        uint256 questID = characterQuest[characterID];
        _submitProgress(questID, tokenIds);
        incrementCharacterQuestProgress(characterID, questID, tokenIds.length);
    }

    function submitWalletProgress(uint256 questID, uint256[] memory tokenIds) public {
        _submitProgress(questID, tokenIds);
        incrementWalletQuestProgress(questID, tokenIds.length);
    }

    function _submitProgress(uint256 questID, uint256[] memory tokenIds) private assertQuestsEnabled {
        require(tokenIds.length != 0, "No tokenIds");
        Quest memory quest = quests[questID];
        if (quest.requirementType == ItemType.WEAPON) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(weapons.ownerOf(tokenID) == msg.sender, "Not weapon owner");
                require(weapons.getStars(tokenID) >= quest.requirementRarity, "Wrong weapon rarity");
            }
            weapons.burnWithoutDust(tokenIds);
        } else if (quest.requirementType == ItemType.JUNK) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(junk.ownerOf(tokenID) == msg.sender, "Not junk owner");
                require(junk.tokenStars(tokenID) >= quest.requirementRarity, "Wrong junk rarity");
            }
            junk.burn(tokenIds);
        } else if (quest.requirementType == ItemType.TRINKET) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(trinket.ownerOf(tokenID) == msg.sender, "Not trinket owner");
                require(trinket.tokenStars(tokenID) >= quest.requirementRarity, "Wrong trinket rarity");
            }
            trinket.burn(tokenIds);
        } else if (quest.requirementType == ItemType.SHIELD) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenID = tokenIds[i];
                require(shields.ownerOf(tokenID) == msg.sender, "Not shield owner");
                require(shields.getStars(tokenID) >= quest.requirementRarity, "Wrong shield rarity");
            }
            shields.burn(tokenIds);
        } else if (quest.requirementType == ItemType.EXTERNAL) {
            partnerVault.storeNfts(IERC721(quest.requirementExternalAddress), tokenIds);
        } else if (quest.requirementType == ItemType.EXTERNAL_HOLD) {
            partnerVault.showHeldNfts(IERC721(quest.requirementExternalAddress), tokenIds, msg.sender);
        } else {
            revert("Unknown requirement type");
        }
    }

    function submitProgressAmount(uint256 characterID, uint256 amount) public assertOnQuest(characterID, true) {
        uint256 questID = characterQuest[characterID];
        _submitProgressAmount(questID, characterID, amount);
        incrementCharacterQuestProgress(characterID, questID, amount);
    }

    function submitWalletProgressAmount(uint256 questID, uint256 amount) public {
        _submitProgressAmount(questID, SEED_REWARD_WALLET_QUEST/*hack number to avoid bumping 0 accidentally*/, amount);
        incrementWalletQuestProgress(questID, amount);
    }

    function _submitProgressAmount(uint256 questID, uint256 characterID, uint256 amount) private assertQuestsEnabled {
        Quest memory quest = quests[questID];
        if (quest.requirementType == ItemType.STAMINA) {
            require(amount <= 255, "Incorrect stamina value");
            characters.getFightDataAndDrainStamina(msg.sender, characterID, uint8(amount), false, 0);
        } else if (quest.requirementType == ItemType.DUST) {
            uint32[] memory decrementDustSupplies = new uint32[](3);
            decrementDustSupplies[quest.requirementRarity] = uint32(amount);
            weapons.decrementDustSupplies(msg.sender, decrementDustSupplies[0], decrementDustSupplies[1], decrementDustSupplies[2]);
        } else if (quest.requirementType == ItemType.SOUL) {
            burningManager.burnSoul(msg.sender, amount);
        } else if (quest.requirementType == ItemType.EXTERNAL) {
            partnerVault.storeCurrency(IERC20(quest.requirementExternalAddress), amount);
        } else {
            revert("Unknown requirement type");
        }
    }

    function incrementCharacterQuestProgress(uint256 characterID, uint256 questID, uint256 progress) private {
        require(progress > 0);
        uint totalProgress = characters.getNftVar(characterID, NFTVAR_SIMPLEQUEST_PROGRESS) + progress;
        characters.setNftVar(characterID, NFTVAR_SIMPLEQUEST_PROGRESS, totalProgress);
        emit QuestProgressed(questID, characterID);
        //.sub reverts on negatives
        if (quests[characterQuest[characterID]].requirementAmount.sub(totalProgress) == 0) {
            _generateRewardQuestSeed(characterID, true);
        }
    }

    function incrementWalletQuestProgress(uint256 questID, uint256 progress) private {
        require(progress > 0);
        require(questID == questTemplates[walletTier][questIndexes[questID]]); // wallet quest tier check
        uint totalProgress = walletQuestProgress[msg.sender][questID] + progress;
        walletQuestProgress[msg.sender][questID] = totalProgress;
        emit WalletQuestProgressed(questID, msg.sender);
        //.sub reverts on negatives
        if (quests[questID].requirementAmount.sub(totalProgress) == 0) {
            _generateRewardWalletQuestSeed(questID, true);
        }
    }

    // VIEWS

    function hasRandomQuestSeedRequested(uint256 characterID) public view returns (bool) {
        return safeRandoms.hasSingleSeedRequest(address(this), RandomUtil.combineSeeds(SEED_RANDOM_QUEST, characterID));
    }

    function hasRandomQuestRewardSeedRequested(uint256 characterID) public view returns (bool) {
        return safeRandoms.hasSingleSeedRequest(address(this), RandomUtil.combineSeeds(SEED_REWARD_QUEST, characterID));
    }

    function hasRandomWalletQuestRewardSeedRequested(uint256 questID) public view returns (bool) {
        return safeRandoms.hasSingleSeedRequest(msg.sender, RandomUtil.combineSeeds(SEED_REWARD_WALLET_QUEST, questID));
    }

    function hasRandomWeeklyRewardSeedRequested(uint256 rewardID) public view returns (bool) {
        return safeRandoms.hasSingleSeedRequest(msg.sender, RandomUtil.combineSeeds(SEED_REWARD_WEEKLY, rewardID));
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

    function getCharacterQuestData(uint256 characterID) public view returns (uint256[] memory) {
        uint256[] memory questDataKeys = new uint256[](3);
        questDataKeys[0] = NFTVAR_SIMPLEQUEST_PROGRESS;
        questDataKeys[1] = NFTVAR_SIMPLEQUEST_TYPE;
        questDataKeys[2] = NFTVAR_REPUTATION;
        return characters.getNFTVars(characterID, questDataKeys);
    }

    function getQuestReward(Quest memory quest) private pure returns (Reward memory) {
        return Reward(quest.id, quest.rewardType, quest.rewardRarity, quest.rewardAmount, quest.rewardExternalAddress, quest.reputationAmount);
    }

    function hasFreeSkip(uint256 characterID) public view returns (bool) {
        return now / 1 days > lastFreeSkipUsage[characterID] / 1 days;
    }

    function nextWeeklyQuestCompletionGoalReset() public view returns (uint256) {
        return now + 1 weeks - now % 1 weeks;
    }

    function nextFreeSkip() public view returns (uint256) {
        return now + 1 days - now % 1 days;
    }

    function getWeeklyCompletions(address user) public view returns (uint256) {
        return weeklyCompletions[user][now / 1 weeks];
    }

    function getWeekNumber() public view returns (uint256) {
        return now / 1 weeks % maxWeeksInAYear + 1;
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

    function addNewQuestTemplate(uint8 tier,
        ItemType requirementType, uint256 requirementRarity, uint256 requirementAmount, address requirementExternalAddress,
        ItemType rewardType, uint256 rewardRarity, uint256 rewardAmount, address rewardExternalAddress,
        uint256 reputationAmount, uint256 supply, uint256 deadline) public restricted {
        uint256 questID = nextQuestID++;
        quests[questID] = Quest(questID, Rarity(tier % 10),
            requirementType, requirementRarity, requirementAmount, requirementExternalAddress,
            rewardType, rewardRarity, rewardAmount, rewardExternalAddress,
            reputationAmount);
        questTemplates[tier].push(questID);
        questIndexes[questID] = questTemplates[tier].length - 1;
        if (supply > 0) {
            require(deadline > 0, "Missing deadline");
            questSupplies[questID] = supply;
            questDeadlines[questID] = deadline;
        }
        if(tier == walletTier) {
            require(requirementType != ItemType.STAMINA && requirementType != ItemType.RAID, "Wrong input");
            require(reputationAmount == 0 && rewardType != ItemType.EXPERIENCE, "Wrong reward");
        }
    }

    function setWeeklyReward(ItemType rewardType, uint256 rewardRarity, uint256 rewardAmount, address rewardExternalAddress, uint256 reputationAmount, uint256 weekNumber, uint256 completionsGoal) public restricted {
        rewards[weekNumber] = Reward(weekNumber, rewardType, rewardRarity, rewardAmount, rewardExternalAddress, reputationAmount);
        weeklyCompletionsGoal[weekNumber] = completionsGoal;
        emit RewardAdded(weekNumber);
    }

    function deleteQuestTemplate(uint256 tier, uint256 questID) public restricted {
        uint256 questIndex = questIndexes[questID];
        uint256 lastQuestId = questTemplates[tier][questTemplates[tier].length - 1];
        questTemplates[tier][questIndex] = lastQuestId;
        questIndexes[lastQuestId] = questIndex;
        questTemplates[tier].pop();
    }
}
