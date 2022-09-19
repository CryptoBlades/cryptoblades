const { upgradeProxy} = require("@openzeppelin/truffle-upgrades");

const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer) {
  await upgradeProxy(Weapons.address, Weapons, { deployer });
  await upgradeProxy(Shields.address, Shields, { deployer });
  await upgradeProxy(Characters.address, Characters, { deployer });
};