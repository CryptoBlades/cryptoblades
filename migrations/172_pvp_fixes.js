const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PvpCore = artifacts.require("PvpCore");
const PvpRankings = artifacts.require("PvpRankings");

module.exports = async function (deployer, network, accounts) {
    await upgradeProxy(PvpCore.address, PvpCore, { deployer });
    await upgradeProxy(PvpRankings.address, PvpRankings, { deployer });
};