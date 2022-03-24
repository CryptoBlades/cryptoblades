const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require('CryptoBlades');
const Blacksmith = artifacts.require("Blacksmith");

module.exports = async function (deployer, network) {
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });

  await game.setVars([19, 20, 21, 22, 23, 24, 25], ['500000000000000', '10000000000000000', '10000000000000000', '1', '10', 0, 0]);
};
