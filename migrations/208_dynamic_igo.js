const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network) {
    await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
};