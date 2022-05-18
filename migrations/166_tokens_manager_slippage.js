const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const TokensManager = artifacts.require("TokensManager");

module.exports = async function (deployer, network) {

    const tokensManager = await upgradeProxy(TokensManager.address, TokensManager, { deployer });
};