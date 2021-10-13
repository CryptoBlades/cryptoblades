const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const CBKLandSale = artifacts.require("CBKLandSale");
const CBKLand = artifacts.require("CBKLand");
module.exports = async function (deployer, network, accounts) {

  const cbkLand = await deployProxy(CBKLand, [], { deployer });
  const cbkLandSale = await deployProxy(CBKLandSale, [cbkLand], { deployer });
 
 
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await blacksmith.migrateTo_bcdf4c(cbkLandSale.address);

  const cbkLandSale_GAME_ADMIN = await cbkLandSale.GAME_ADMIN();
  await cbkLandSale.grantRole(cbkLandSale_GAME_ADMIN, blacksmith.address);
  
  const cbkLand_GAME_ADMIN = await cbkLand.GAME_ADMIN();
  await cbkLand.grantRole(cbkLandSale_GAME_ADMIN, cbkLandSale.address);
};