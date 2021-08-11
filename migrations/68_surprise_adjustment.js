const { upgradeProxy, deployProxy } = require('@openzeppelin/truffle-upgrades');

const Promos = artifacts.require('Promos');
const NFTMarket = artifacts.require("NFTMarket");

module.exports = async function (deployer, network, accounts) {
  const promos = await upgradeProxy(Promos.address, Promos, { deployer });
  const market = await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
};
