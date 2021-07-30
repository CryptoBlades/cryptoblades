const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(Weapons.address, Weapons, { deployer });
};
