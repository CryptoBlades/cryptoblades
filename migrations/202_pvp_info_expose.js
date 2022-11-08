const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const PvpCore = artifacts.require("PvpCore");

module.exports = async function (deployer, network, accounts) {
    await upgradeProxy(PvpCore.address, PvpCore, { deployer });
};