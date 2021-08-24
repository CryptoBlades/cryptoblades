const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Raid1 = artifacts.require("Raid1");
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {
  const raid1 = await upgradeProxy(Raid1.address, Raid1, { deployer });
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
};
