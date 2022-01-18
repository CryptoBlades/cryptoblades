const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Junk = artifacts.require("Junk");
const RaidTrinket = artifacts.require("RaidTrinket");
const Shields = artifacts.require("Shields");

//TODO: Dev-only, do not use!
module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(Characters.address, Characters, {deployer});
  await upgradeProxy(Weapons.address, Weapons, {deployer});
  await upgradeProxy(Junk.address, Junk, {deployer});
  await upgradeProxy(RaidTrinket.address, RaidTrinket, {deployer});
  await upgradeProxy(Shields.address, Shields, {deployer});
  await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
};
