const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTMarket = artifacts.require("NFTMarket");
const BurningManager = artifacts.require("BurningManager");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(BurningManager.address, BurningManager, { deployer });
  await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
};
