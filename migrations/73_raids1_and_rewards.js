const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Raid1 = artifacts.require("Raid1");
const KeyLootbox = artifacts.require("KeyLootbox");
const RaidTrinket = artifacts.require("RaidTrinket");
const Junk = artifacts.require("Junk");

module.exports = async function (deployer, network, accounts) {

  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  const chars = await upgradeProxy(Characters.address, Characters, { deployer });
  const weps = await upgradeProxy(Weapons.address, Weapons, { deployer });

  const promosAddress = await game.promos();

  const keyLootbox = await deployProxy(KeyLootbox, [promosAddress], { deployer });
  const raidTrinket = await deployProxy(RaidTrinket, [promosAddress], { deployer });
  const junk = await deployProxy(Junk, [promosAddress], { deployer });

  const raid1 = await deployProxy(Raid1, [CryptoBlades.address], { deployer });

  const GAME_ADMIN = await raid1.GAME_ADMIN();
  await game.grantRole(GAME_ADMIN, raid1.address);
  await chars.grantRole(GAME_ADMIN, raid1.address);
  await weps.grantRole(GAME_ADMIN, raid1.address);
  await keyLootbox.grantRole(GAME_ADMIN, raid1.address);
  await raidTrinket.grantRole(GAME_ADMIN, raid1.address);
  await junk.grantRole(GAME_ADMIN, raid1.address);

  const LINK_KEYBOX = await raid1.LINK_KEYBOX();
  const LINK_TRINKET = await raid1.LINK_TRINKET();
  const LINK_JUNK = await raid1.LINK_JUNK();
  await raid1.registerLink(keyLootbox.address, LINK_KEYBOX);
  await raid1.registerLink(raidTrinket.address, LINK_TRINKET);
  await raid1.registerLink(junk.address, LINK_JUNK);
};
