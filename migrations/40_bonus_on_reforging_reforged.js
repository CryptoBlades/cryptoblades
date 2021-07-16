const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer) {
  await upgradeProxy(Weapons.address, Weapons, { deployer });
};
