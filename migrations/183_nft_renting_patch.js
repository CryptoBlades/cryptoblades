const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const CryptoBlades = artifacts.require("CryptoBlades");
const TokensManager = artifacts.require("TokensManager");
const PvpRankings = artifacts.require("PvpRankings");
const PvpCore = artifacts.require("PvpCore");


module.exports = async function (deployer, network, accounts) {
    await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    await upgradeProxy(TokensManager.address, TokensManager, { deployer });
    await upgradeProxy(PvpRankings.address, PvpRankings, { deployer });
    await upgradeProxy(PvpCore.address, PvpCore, { deployer });
};