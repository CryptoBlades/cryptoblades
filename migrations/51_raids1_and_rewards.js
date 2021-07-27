const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Raid1 = artifacts.require("Raid1");
const Junk = artifacts.require("Junk");
const KeyLootbox = artifacts.require("KeyLootbox");
const RaidTrinket = artifacts.require("RaidTrinket");
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {

  const raid1 = await deployProxy(Raid1, [CryptoBlades.address], { deployer });
  const junk = await deployProxy(Junk, [], { deployer });
  const keyLootbox = await deployProxy(KeyLootbox, [], { deployer });
  const raidTrinket = await deployProxy(RaidTrinket, [], { deployer });

};
