const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PvpRankings = artifacts.require("PvpRankings");

module.exports = async function (deployer, network, accounts) {
    await upgradeProxy(PvpRankings.address, PvpRankings, { deployer });
};