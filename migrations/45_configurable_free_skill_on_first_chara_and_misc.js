const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Weapons = artifacts.require("Weapons");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer, network, accounts) {
  const promos = await upgradeProxy(Promos.address, Promos, { deployer });

  await promos.migrateTo_f73df27();

  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(Weapons.address, Weapons, { deployer });
};
