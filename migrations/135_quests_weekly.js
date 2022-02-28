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
  if (network === "development"
    || network === "development-fork"
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet'
    || network === 'avaxtestnet'
    || network === 'avaxtestnet-fork'
    || network === 'auroratestnet') {
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
    const VAR_WEEKLY_COMPLETIONS_GOAL = await simpleQuests.VAR_WEEKLY_COMPLETIONS_GOAL();
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
      VAR_WEEKLY_COMPLETIONS_GOAL
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
      5
    ]);
    await simpleQuests.setTierChances(0, [100, 100, 100, 100]);
    await simpleQuests.setTierChances(1, [85, 100, 100, 100]);
    await simpleQuests.setTierChances(2, [77, 97, 100, 100]);
    await simpleQuests.setTierChances(3, [69, 94, 100, 100]);
    await simpleQuests.setTierChances(4, [66, 93, 99, 100]);

    // TODO: Is this needed? Ofc we need the partnerVault one
    await characters.grantRole(await characters.GAME_ADMIN(), simpleQuests.address);
    await weapons.grantRole(await weapons.GAME_ADMIN(), simpleQuests.address);
    await junk.grantRole(await junk.GAME_ADMIN(), simpleQuests.address);
    await trinket.grantRole(await trinket.GAME_ADMIN(), simpleQuests.address);
    await shields.grantRole(await shields.GAME_ADMIN(), simpleQuests.address);
    await burningManager.grantRole(await burningManager.GAME_ADMIN(), simpleQuests.address);
    await safeRandoms.grantRole(await safeRandoms.GAME_ADMIN(), simpleQuests.address);
    await partnerVault.grantRole(await partnerVault.GAME_ADMIN(), simpleQuests.address);
  }
};
