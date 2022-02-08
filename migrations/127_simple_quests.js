const {deployProxy, upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Junk = artifacts.require("Junk");
const RaidTrinket = artifacts.require("RaidTrinket");
const Shields = artifacts.require("Shields");
const BurningManager = artifacts.require("BurningManager");
const SafeRandoms = artifacts.require("SafeRandoms");
const Raid1 = artifacts.require("Raid1");

module.exports = async function (deployer, network, accounts) {
  if (network === "development"
    || network === "development-fork"
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet'
    || network === 'avaxtestnet'
    || network === 'avaxtestnet-fork') {
    const characters = await upgradeProxy(Characters.address, Characters, {deployer});
    const weapons = await upgradeProxy(Weapons.address, Weapons, {deployer});
    const junk = await upgradeProxy(Junk.address, Junk, {deployer});
    const trinket = await upgradeProxy(RaidTrinket.address, RaidTrinket, {deployer});
    const shields = await upgradeProxy(Shields.address, Shields, {deployer});
    const burningManager = await upgradeProxy(BurningManager.address, BurningManager, {deployer});
    const safeRandoms = await SafeRandoms.deployed();
    await upgradeProxy(Raid1.address, Raid1, {deployer});
    const simpleQuests = await deployProxy(SimpleQuests, [characters.address, weapons.address, junk.address, trinket.address, shields.address, burningManager.address, safeRandoms.address], {deployer});
    // TODO: What should be the initial values here?
    // const VAR_COMMON_TIER = 0;
    // await simpleQuests.setVar(VAR_COMMON_TIER, 0); Leaving this as a comment, because it's 0 by default
    const VAR_UNCOMMON_TIER = await simpleQuests.VAR_UNCOMMON_TIER();
    const VAR_RARE_TIER = await simpleQuests.VAR_RARE_TIER();
    const VAR_EPIC_TIER = await simpleQuests.VAR_EPIC_TIER();
    const VAR_LEGENDARY_TIER = await simpleQuests.VAR_LEGENDARY_TIER();
    const VAR_REPUTATION_LEVEL_2 = await simpleQuests.VAR_REPUTATION_LEVEL_2();
    const VAR_REPUTATION_LEVEL_3 = await simpleQuests.VAR_REPUTATION_LEVEL_3();
    const VAR_REPUTATION_LEVEL_4 = await simpleQuests.VAR_REPUTATION_LEVEL_4();
    const VAR_REPUTATION_LEVEL_5 = await simpleQuests.VAR_REPUTATION_LEVEL_5();
    const VAR_SKIP_QUEST_STAMINA_COST = await simpleQuests.VAR_SKIP_QUEST_STAMINA_COST();
    await simpleQuests.setVar(VAR_UNCOMMON_TIER, 1);
    await simpleQuests.setVar(VAR_RARE_TIER, 2);
    await simpleQuests.setVar(VAR_EPIC_TIER, 3);
    await simpleQuests.setVar(VAR_LEGENDARY_TIER, 4);
    await simpleQuests.setVar(VAR_REPUTATION_LEVEL_2, 1000);
    await simpleQuests.setVar(VAR_REPUTATION_LEVEL_3, 2000);
    await simpleQuests.setVar(VAR_REPUTATION_LEVEL_4, 5000);
    await simpleQuests.setVar(VAR_REPUTATION_LEVEL_5, 10000);
    await simpleQuests.setVar(VAR_SKIP_QUEST_STAMINA_COST, 40);
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
  }
};
