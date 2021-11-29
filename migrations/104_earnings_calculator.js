const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer) {
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
};
