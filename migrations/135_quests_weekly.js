const {deployProxy, upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Junk = artifacts.require("Junk");
const RaidTrinket = artifacts.require("RaidTrinket");
const Shields = artifacts.require("Shields");
const BurningManager = artifacts.require("BurningManager");
const SafeRandoms = artifacts.require("SafeRandoms");
const PartnerVault = artifacts.require("PartnerVault");

module.exports = async function (deployer, network) {
  const characters = await upgradeProxy(Characters.address, Characters, {deployer});
  const weapons = await Weapons.deployed();
  const junk = await Junk.deployed();
  const trinket = await RaidTrinket.deployed();
  const shields = await Shields.deployed();
  const burningManager = await upgradeProxy(BurningManager.address, BurningManager, {deployer});
  const safeRandoms = await SafeRandoms.deployed();
  const partnerVault = await deployProxy(PartnerVault, [], {deployer});
  const simpleQuests = await deployProxy(SimpleQuests, [characters.address, weapons.address, junk.address, trinket.address, shields.address, burningManager.address, safeRandoms.address, partnerVault.address], {deployer});
  const VAR_UNCOMMON_TIER = await simpleQuests.VAR_UNCOMMON_TIER();
  const VAR_RARE_TIER = await simpleQuests.VAR_RARE_TIER();
  const VAR_EPIC_TIER = await simpleQuests.VAR_EPIC_TIER();
  const VAR_LEGENDARY_TIER = await simpleQuests.VAR_LEGENDARY_TIER();
  const VAR_REPUTATION_LEVEL_2 = await simpleQuests.VAR_REPUTATION_LEVEL_2();
  const VAR_REPUTATION_LEVEL_3 = await simpleQuests.VAR_REPUTATION_LEVEL_3();
  const VAR_REPUTATION_LEVEL_4 = await simpleQuests.VAR_REPUTATION_LEVEL_4();
  const VAR_REPUTATION_LEVEL_5 = await simpleQuests.VAR_REPUTATION_LEVEL_5();
  const VAR_SKIP_QUEST_STAMINA_COST = await simpleQuests.VAR_SKIP_QUEST_STAMINA_COST();
  // const VAR_WEEKLY_COMPLETIONS_GOAL = await simpleQuests.VAR_WEEKLY_COMPLETIONS_GOAL();
  const VAR_CONTRACT_ENABLED = await simpleQuests.VAR_CONTRACT_ENABLED();
  //Leaving this as a comment, because it's 0 by default
  await simpleQuests.setVars([
    // VAR_COMMON_TIER,
    VAR_UNCOMMON_TIER,
    VAR_RARE_TIER,
    VAR_EPIC_TIER,
    VAR_LEGENDARY_TIER,
    VAR_REPUTATION_LEVEL_2,
    VAR_REPUTATION_LEVEL_3,
    VAR_REPUTATION_LEVEL_4,
    VAR_REPUTATION_LEVEL_5,
    VAR_SKIP_QUEST_STAMINA_COST,
    // VAR_WEEKLY_COMPLETIONS_GOAL,
    VAR_CONTRACT_ENABLED
  ], [
    // 0,
    1,
    2,
    3,
    4,
    25,
    120,
    375,
    1000,
    40,
    // 5,
    1
  ]);
  await simpleQuests.setTierChances(0, [100, 100, 100, 100]);
  await simpleQuests.setTierChances(1, [85, 100, 100, 100]);
  await simpleQuests.setTierChances(2, [77, 97, 100, 100]);
  await simpleQuests.setTierChances(3, [69, 94, 100, 100]);
  await simpleQuests.setTierChances(4, [66, 93, 99, 100]);

  await characters.grantRole(await characters.GAME_ADMIN(), simpleQuests.address);
  await weapons.grantRole(await weapons.GAME_ADMIN(), simpleQuests.address);
  await junk.grantRole(await junk.GAME_ADMIN(), simpleQuests.address);
  await trinket.grantRole(await trinket.GAME_ADMIN(), simpleQuests.address);
  await shields.grantRole(await shields.GAME_ADMIN(), simpleQuests.address);
  await burningManager.grantRole(await burningManager.GAME_ADMIN(), simpleQuests.address);
  await safeRandoms.grantRole(await safeRandoms.GAME_ADMIN(), simpleQuests.address);
  await partnerVault.grantRole(await partnerVault.GAME_ADMIN(), simpleQuests.address);

  // COMMON QUESTS
  await simpleQuests.addNewQuestTemplate(0, 1, 0, 2, '0x0000000000000000000000000000000000000000', 1, 1, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 3, 0, 2, '0x0000000000000000000000000000000000000000', 2, 0, 1, '0x0000000000000000000000000000000000000000', 11, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 2, 0, 2, '0x0000000000000000000000000000000000000000', 2, 1, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 1, 0, 2, '0x0000000000000000000000000000000000000000', 2, 1, 2, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 2, 1, 2, '0x0000000000000000000000000000000000000000', 2, 2, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 1, 1, 2, '0x0000000000000000000000000000000000000000', 2, 2, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 6, 0, 280, '0x0000000000000000000000000000000000000000', 1, 0, 1, '0x0000000000000000000000000000000000000000', 12, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 8, 0, 1, '0x0000000000000000000000000000000000000000', 1, 0, 1, '0x0000000000000000000000000000000000000000', 8, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 6, 0, 560, '0x0000000000000000000000000000000000000000', 1, 1, 1, '0x0000000000000000000000000000000000000000', 13, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 8, 0, 2, '0x0000000000000000000000000000000000000000', 1, 1, 1, '0x0000000000000000000000000000000000000000', 11, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 6, 0, 150, '0x0000000000000000000000000000000000000000', 3, 0, 1, '0x0000000000000000000000000000000000000000', 12, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 2, 0, 2, '0x0000000000000000000000000000000000000000', 2, 0, 1, '0x0000000000000000000000000000000000000000', 14, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 1, 0, 1, '0x0000000000000000000000000000000000000000', 9, 0, 7, '0x0000000000000000000000000000000000000000', 13, 0, 0);
  await simpleQuests.addNewQuestTemplate(0, 2, 0, 3, '0x0000000000000000000000000000000000000000', 1, 1, 1, '0x0000000000000000000000000000000000000000', 11, 0, 0);

  // UNCOMMON QUESTS
  await simpleQuests.addNewQuestTemplate(1, 6, 0, 40, '0x0000000000000000000000000000000000000000', 9, 0, 33, '0x0000000000000000000000000000000000000000', 11, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 6, 0, 200, '0x0000000000000000000000000000000000000000', 9, 0, 168, '0x0000000000000000000000000000000000000000', 11, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 1, 1, 1, '0x0000000000000000000000000000000000000000', 9, 0, 16, '0x0000000000000000000000000000000000000000', 14, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 1, 2, 1, '0x0000000000000000000000000000000000000000', 9, 0, 69, '0x0000000000000000000000000000000000000000', 12, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 2, 2, 4, '0x0000000000000000000000000000000000000000', 2, 3, 1, '0x0000000000000000000000000000000000000000', 11, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 1, 2, 2, '0x0000000000000000000000000000000000000000', 2, 3, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 2, 1, 5, '0x0000000000000000000000000000000000000000', 2, 3, 1, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 1, 1, 3, '0x0000000000000000000000000000000000000000', 1, 2, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 2, 2, 2, '0x0000000000000000000000000000000000000000', 1, 2, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 3, 0, 17, '0x0000000000000000000000000000000000000000', 1, 2, 1, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 8, 0, 6, '0x0000000000000000000000000000000000000000', 1, 2, 1, '0x0000000000000000000000000000000000000000', 7, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 1, 0, 1, '0x0000000000000000000000000000000000000000', 1, 1, 1, '0x0000000000000000000000000000000000000000', 0, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 6, 0, 200, '0x0000000000000000000000000000000000000000', 1, 0, 1, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 8, 0, 4, '0x0000000000000000000000000000000000000000', 1, 0, 5, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 6, 0, 400, '0x0000000000000000000000000000000000000000', 1, 1, 1, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 8, 0, 5, '0x0000000000000000000000000000000000000000', 1, 1, 3, '0x0000000000000000000000000000000000000000', 8, 0, 0);
  await simpleQuests.addNewQuestTemplate(1, 1, 2, 1, '0x0000000000000000000000000000000000000000', 1, 2, 1, '0x0000000000000000000000000000000000000000', 0, 0, 0);

  // RARE QUESTS
  await simpleQuests.addNewQuestTemplate(2, 6, 0, 40, '0x0000000000000000000000000000000000000000', 9, 0, 35, '0x0000000000000000000000000000000000000000', 6, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 1, 3, 1, '0x0000000000000000000000000000000000000000', 9, 0, 290, '0x0000000000000000000000000000000000000000', 8, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 8, 0, 3, '0x0000000000000000000000000000000000000000', 9, 0, 135, '0x0000000000000000000000000000000000000000', 12, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 2, 2, 1, '0x0000000000000000000000000000000000000000', 9, 0, 36, '0x0000000000000000000000000000000000000000', 7, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 3, 1, 1, '0x0000000000000000000000000000000000000000', 9, 0, 235, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 2, 3, 2, '0x0000000000000000000000000000000000000000', 2, 4, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 1, 2, 4, '0x0000000000000000000000000000000000000000', 2, 4, 1, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 1, 2, 4, '0x0000000000000000000000000000000000000000', 1, 3, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 2, 3, 2, '0x0000000000000000000000000000000000000000', 1, 3, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 2, 3, 2, '0x0000000000000000000000000000000000000000', 3, 1, 1, '0x0000000000000000000000000000000000000000', 12, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 8, 0, 3, '0x0000000000000000000000000000000000000000', 1, 2, 1, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 1, 3, 1, '0x0000000000000000000000000000000000000000', 1, 3, 1, '0x0000000000000000000000000000000000000000', 0, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 3, 0, 35, '0x0000000000000000000000000000000000000000', 3, 1, 1, '0x0000000000000000000000000000000000000000', 12, 0, 0);
  await simpleQuests.addNewQuestTemplate(2, 1, 2, 6, '0x0000000000000000000000000000000000000000', 3, 1, 1, '0x0000000000000000000000000000000000000000', 14, 0, 0);

  // EPIC QUESTS
  await simpleQuests.addNewQuestTemplate(3, 6, 0, 80, '0x0000000000000000000000000000000000000000', 9, 0, 80, '0x0000000000000000000000000000000000000000', 10, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 2, 3, 1, '0x0000000000000000000000000000000000000000', 9, 0, 153, '0x0000000000000000000000000000000000000000', 11, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 2, 4, 1, '0x0000000000000000000000000000000000000000', 9, 0, 337, '0x0000000000000000000000000000000000000000', 11, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 1, 4, 1, '0x0000000000000000000000000000000000000000', 9, 0, 1800, '0x0000000000000000000000000000000000000000', 12, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 1, 3, 5, '0x0000000000000000000000000000000000000000', 1, 4, 1, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 2, 4, 5, '0x0000000000000000000000000000000000000000', 1, 4, 1, '0x0000000000000000000000000000000000000000', 9, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 8, 0, 18, '0x0000000000000000000000000000000000000000', 1, 3, 1, '0x0000000000000000000000000000000000000000', 13, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 2, 3, 1, '0x0000000000000000000000000000000000000000', 3, 1, 1, '0x0000000000000000000000000000000000000000', 6, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 2, 4, 3, '0x0000000000000000000000000000000000000000', 3, 2, 1, '0x0000000000000000000000000000000000000000', 7, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 1, 4, 1, '0x0000000000000000000000000000000000000000', 1, 4, 1, '0x0000000000000000000000000000000000000000', 0, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 3, 0, 50, '0x0000000000000000000000000000000000000000', 3, 1, 2, '0x0000000000000000000000000000000000000000', 6, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 1, 2, 4, '0x0000000000000000000000000000000000000000', 3, 1, 1, '0x0000000000000000000000000000000000000000', 7, 0, 0);
  await simpleQuests.addNewQuestTemplate(3, 3, 1, 4, '0x0000000000000000000000000000000000000000', 3, 2, 1, '0x0000000000000000000000000000000000000000', 9, 0, 0);
};
