const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Blacksmith = artifacts.require("Blacksmith");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  const weapons = await Weapons.deployed();

  const GAME_ADMIN = await weapons.GAME_ADMIN();
  await weapons.grantRole(GAME_ADMIN, blacksmith.address);
};
