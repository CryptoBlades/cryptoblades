const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTMarket = artifacts.require("NFTMarket");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
};
