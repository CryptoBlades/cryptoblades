const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const Weapons = artifacts.require("Weapons");
const Blacksmith = artifacts.require("Blacksmith");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer) {
  await upgradeProxy(Weapons.address, Weapons, { deployer });
  await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await upgradeProxy(Promos.address, Promos, { deployer });
};