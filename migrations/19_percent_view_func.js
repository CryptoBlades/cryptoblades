const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTMarket = artifacts.require("NFTMarket");

module.exports = async function (deployer) {
  const market = await NFTMarket.deployed();
  await upgradeProxy(market.address, NFTMarket, { deployer });
};
