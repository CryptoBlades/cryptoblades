const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer) {
  const game = await CryptoBlades.deployed();

  await upgradeProxy(game.address, CryptoBlades, { deployer });
};
