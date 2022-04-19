const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PvpCore = artifacts.require("PvpCore");

module.exports = async function (deployer, network) {

    const pvp = await upgradeProxy(PvpCore.address, PvpCore, { deployer });
};