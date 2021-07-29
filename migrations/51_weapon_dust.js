const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(Characters.address, Characters, { deployer });
  await upgradeProxy(Weapons.address, Weapons, { deployer });
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await game.migrateTo_801f279();
};
