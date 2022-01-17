const {deployProxy, upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Junk = artifacts.require("Junk");
const RaidTrinket = artifacts.require("RaidTrinket");

module.exports = async function (deployer, network, accounts) {
  const characters = await upgradeProxy(Characters.address, Characters, {deployer});
  const weapons = await upgradeProxy(Weapons.address, Weapons, {deployer});
  const junk = await upgradeProxy(Junk.address, Junk, {deployer});
  const trinket = await upgradeProxy(RaidTrinket.address, RaidTrinket, {deployer});
  const simpleQuests = await deployProxy(SimpleQuests, [characters.address, weapons.address, junk.address, trinket.address], {deployer});
  await characters.grantRole(await characters.GAME_ADMIN(), simpleQuests.address);
  await weapons.grantRole(await weapons.GAME_ADMIN(), simpleQuests.address);
  await junk.grantRole(await junk.GAME_ADMIN(), simpleQuests.address);
  await trinket.grantRole(await trinket.GAME_ADMIN(), simpleQuests.address);
};
