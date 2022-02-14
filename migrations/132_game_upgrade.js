const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer, network) {
    await upgradeProxy(Characters.address, Characters, { deployer });
    await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
};