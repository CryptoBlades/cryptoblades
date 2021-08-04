const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(Weapons.address, Weapons, { deployer });
};
