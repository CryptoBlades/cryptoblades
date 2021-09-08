const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const RaidBasic = artifacts.require("RaidBasic");

module.exports = async function (deployer) {
  const charas = await Characters.deployed();
  await upgradeProxy(charas.address, Characters, { deployer });

  const weps = await Weapons.deployed();
  const newWeps = await upgradeProxy(weps.address, Weapons, { deployer });
  await newWeps.migrateTo_aa9da90();

  const game = await CryptoBlades.deployed();
  await upgradeProxy(game.address, CryptoBlades, { deployer });

  const raidBasic = await RaidBasic.deployed();
  await upgradeProxy(raidBasic.address, RaidBasic, { deployer });
};
