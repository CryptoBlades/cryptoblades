const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Raid1 = artifacts.require("Raid1");
const Junk = artifacts.require("Junk");
const KeyLootbox = artifacts.require("KeyLootbox");
const RaidTrinket = artifacts.require("RaidTrinket");
const CryptoBlades = artifacts.require("CryptoBlades");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network, accounts) {

  const junk = await deployProxy(Junk, [], { deployer });
  const keyLootbox = await deployProxy(KeyLootbox, [], { deployer });
  const raidTrinket = await deployProxy(RaidTrinket, [], { deployer });
  const weps = await deployProxy(Weapons, [], { deployer });

  const raid1 = await deployProxy(Raid1, [CryptoBlades.address], { deployer });

  const GAME_ADMIN = await raid1.GAME_ADMIN();
  //await game.grantRole(GAME_ADMIN, raid1.address);
  await keyLootbox.grantRole(GAME_ADMIN, raid1.address);
  await raidTrinket.grantRole(GAME_ADMIN, raid1.address);
  await weps.grantRole(GAME_ADMIN, raid1.address);
  await junk.grantRole(GAME_ADMIN, raid1.address);

  const REWARD_ERC721SEEDED_KEYBOX = await raid1.REWARD_ERC721SEEDED_KEYBOX();
  const REWARD_ERC721SEEDEDSTARS_TRINKET = await raid1.REWARD_ERC721SEEDEDSTARS_TRINKET();
  const REWARD_ERC721SEEDEDSTARS_WEAPON = await raid1.REWARD_ERC721SEEDEDSTARS_WEAPON();
  const REWARD_ERC721SEEDEDSTARS_JUNK = await raid1.REWARD_ERC721SEEDEDSTARS_JUNK();
  await raid1.registerERC721RewardSeededAddress(keyLootbox.address, REWARD_ERC721SEEDED_KEYBOX);
  await raid1.registerERC721RewardSeededStarsAddress(keyLootbox.address, REWARD_ERC721SEEDEDSTARS_TRINKET);
  await raid1.registerERC721RewardSeededStarsAddress(raidTrinket.address, REWARD_ERC721SEEDEDSTARS_WEAPON);
  await raid1.registerERC721RewardSeededStarsAddress(junk.address, REWARD_ERC721SEEDEDSTARS_JUNK);
};
