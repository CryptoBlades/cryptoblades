const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Weapons = artifacts.require("Weapons");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(Weapons.address, Weapons, { deployer });
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

  await game.migrateTo_5e833b0();
};
