const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer) {
  const charas = await Characters.deployed();
  const newCharas = await upgradeProxy(charas.address, Characters, { deployer });
  await newCharas.migrateTo_1ee400a();

  const game = await CryptoBlades.deployed();
  await upgradeProxy(game.address, CryptoBlades, { deployer });
};
