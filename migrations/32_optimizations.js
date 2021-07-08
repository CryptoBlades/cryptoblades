const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer) {
  const game = await CryptoBlades.deployed();
  await upgradeProxy(game.address, CryptoBlades, { deployer });

  const weps = await Weapons.deployed();
  await upgradeProxy(weps.address, Weapons, { deployer });
};
