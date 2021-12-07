const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CBKLandSale = artifacts.require("CBKLandSale");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CBKLandSale.address, CBKLandSale, { deployer });
};