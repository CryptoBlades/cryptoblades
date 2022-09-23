const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const TokensManager = artifacts.require("TokensManager");

module.exports = async function (deployer) {
  await upgradeProxy(TokensManager.address, TokensManager, { deployer });
};
