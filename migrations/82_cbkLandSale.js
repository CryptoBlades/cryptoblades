const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const CBKLandSale = artifacts.require("CBKLandSale");

module.exports = async function (deployer, network, accounts) {

  const cbkLandSale = await deployProxy(CBKLandSale, { deployer });
 
 
 const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await blacksmith.migrateTo_bcdf4c(cbkLandSale.address);

  const cbkLandSale_GAME_ADMIN = await cbkLandSale.GAME_ADMIN();
  await cbkLandSale.grantRole(cbkLandSale_GAME_ADMIN, blacksmith.address);
};