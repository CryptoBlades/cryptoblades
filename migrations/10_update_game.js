const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer) {
  const game = await CryptoBlades.deployed();

  const newGame = await upgradeProxy(game.address, CryptoBlades, { deployer });

  console.log('Upgraded', newGame.address);
};
