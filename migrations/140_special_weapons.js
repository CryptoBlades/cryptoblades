const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const Weapons = artifacts.require("Weapons");
const Blacksmith = artifacts.require("Blacksmith");
const Promos = artifacts.require("Promos");
const SafeRandoms = artifacts.require("SafeRandoms");
const SpecialWeaponsManager = artifacts.require("SpecialWeaponsManager");

module.exports = async function (deployer) {
  let weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
  await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  let promos = await upgradeProxy(Promos.address, Promos, { deployer });
  let safeRandoms = await SafeRandoms.deployed();
  await deployProxy(SpecialWeaponsManager, [promos.address, weapons.address, safeRandoms.address], { deployer });

};