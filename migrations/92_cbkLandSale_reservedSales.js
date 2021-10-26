const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Blacksmith = artifacts.require("Blacksmith");
const CBKLandSale = artifacts.require("CBKLandSale");
const CBKLand = artifacts.require("CBKLand");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await upgradeProxy(CBKLand.address, CBKLand, { deployer });
  await upgradeProxy(CBKLandSale.address, CBKLandSale, { deployer });
};