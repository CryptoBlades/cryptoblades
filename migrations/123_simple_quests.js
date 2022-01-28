const {deployProxy, upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Junk = artifacts.require("Junk");
const RaidTrinket = artifacts.require("RaidTrinket");
const Shields = artifacts.require("Shields");
const SafeRandoms = artifacts.require("SafeRandoms");

module.exports = async function (deployer, network, accounts) {
  const VAR_COMMON_TIER = 0;
  const VAR_UNCOMMON_TIER = 1;
  const VAR_RARE_TIER = 2;
  const VAR_EPIC_TIER = 3;
  const VAR_LEGENDARY_TIER = 4;
  const VAR_CONTRACT_ENABLED = 9;
  const VAR_REPUTATION_LEVEL_2 = 20;
  const VAR_REPUTATION_LEVEL_3 = 21;
  const VAR_REPUTATION_LEVEL_4 = 22;
  const VAR_REPUTATION_LEVEL_5 = 23;
  const characters = await upgradeProxy(Characters.address, Characters, {deployer});
  const weapons = await upgradeProxy(Weapons.address, Weapons, {deployer});
  const junk = await upgradeProxy(Junk.address, Junk, {deployer});
  const trinket = await upgradeProxy(RaidTrinket.address, RaidTrinket, {deployer});
  const shields = await upgradeProxy(Shields.address, Shields, {deployer});
  const safeRandoms = await upgradeProxy(SafeRandoms.address, SafeRandoms, {deployer});
  const simpleQuests = await deployProxy(SimpleQuests, [characters.address, weapons.address, junk.address, trinket.address, shields.address, safeRandoms.address], {deployer});
  // TODO: What should be the initial values here?
  await simpleQuests.setVar(VAR_COMMON_TIER, 0);
  await simpleQuests.setVar(VAR_UNCOMMON_TIER, 1);
  await simpleQuests.setVar(VAR_RARE_TIER, 2);
  await simpleQuests.setVar(VAR_EPIC_TIER, 3);
  await simpleQuests.setVar(VAR_LEGENDARY_TIER, 4);
  await simpleQuests.setVar(VAR_REPUTATION_LEVEL_2, 1000);
  await simpleQuests.setVar(VAR_REPUTATION_LEVEL_3, 2000);
  await simpleQuests.setVar(VAR_REPUTATION_LEVEL_4, 5000);
  await simpleQuests.setVar(VAR_REPUTATION_LEVEL_5, 10000);
  await simpleQuests.setVar(VAR_CONTRACT_ENABLED, 0);

  await characters.grantRole(await characters.GAME_ADMIN(), simpleQuests.address);
  await weapons.grantRole(await weapons.GAME_ADMIN(), simpleQuests.address);
  await junk.grantRole(await junk.GAME_ADMIN(), simpleQuests.address);
  await trinket.grantRole(await trinket.GAME_ADMIN(), simpleQuests.address);
  await shields.grantRole(await shields.GAME_ADMIN(), simpleQuests.address);
  await safeRandoms.grantRole(await shields.GAME_ADMIN(), simpleQuests.address);
};
