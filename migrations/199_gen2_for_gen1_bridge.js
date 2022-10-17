const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const ShieldBridgeProxyContract = artifacts.require("ShieldBridgeProxyContract");
const WeaponBridgeProxyContract = artifacts.require("WeaponBridgeProxyContract");
const CharactersBridgeProxyContract = artifacts.require("CharactersBridgeProxyContract");
const CBKLandBridgeProxyContract = artifacts.require("CBKLandBridgeProxyContract");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer, network) {
  await upgradeProxy(ShieldBridgeProxyContract.address, ShieldBridgeProxyContract, { deployer }); 
  await upgradeProxy(WeaponBridgeProxyContract.address, WeaponBridgeProxyContract, { deployer }); 
  await upgradeProxy(CBKLandBridgeProxyContract.address, CBKLandBridgeProxyContract, { deployer }); 
  const charactersBridgeProxy = await upgradeProxy(CharactersBridgeProxyContract.address, CharactersBridgeProxyContract, { deployer }); 
  await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });

  const promos = await Promos.deployed();
  await charactersBridgeProxy.migrate_c906001(promos.address);
};