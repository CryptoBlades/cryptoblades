const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');


const CBKLandSale = artifacts.require("CBKLandSale");
const CBKLand = artifacts.require("CBKLand");
module.exports = async function (deployer, network, accounts) {

  await upgradeProxy(CBKLand.address, CBKLand, { deployer });
  await upgradeProxy(CBKLandSale.address, CBKLandSale, { deployer });
};