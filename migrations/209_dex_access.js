const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const Dex = artifacts.require("Dex");

module.exports = async function (deployer) {
    await upgradeProxy(Dex.address, Dex, { deployer });
    // This upgrade adds the variable VAR_CONTRACT_ENABLED to toggle access (0 = off, 1 = on),
    // It's left off by default out of caution
};