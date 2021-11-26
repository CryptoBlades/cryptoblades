const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Raid1 = artifacts.require("Raid1");

module.exports = async function (deployer, network, accounts) {

  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  const chars = await upgradeProxy(Characters.address, Characters, { deployer });
  const weps = await upgradeProxy(Weapons.address, Weapons, { deployer });
  const raid1 = await upgradeProxy(Raid1.address, Raid1, { deployer });
};
