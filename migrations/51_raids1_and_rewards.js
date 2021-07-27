const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Raids1 = artifacts.require("Raids1");
const Junk = artifacts.require("Junk");
const KeyLootbox = artifacts.require("KeyLootbox");
const RaidTrinket = artifacts.require("RaidTrinket");

module.exports = async function (deployer, network, accounts) {
  const raids1 = await deployProxy(Raids1, [], { deployer });
  const junk = await deployProxy(Junk, [], { deployer });
  const keyLootbox = await deployProxy(KeyLootbox, [], { deployer });
  const raidTrinket = await deployProxy(RaidTrinket, [], { deployer });

};
