const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const CBKLandBridgeProxyContract = artifacts.require("CBKLandBridgeProxyContract");
const CBKLand = artifacts.require("CBKLand");

module.exports = async function (deployer, network) {
  if (network === "development"
  || network === "development-fork"
  || network === 'bsctestnet'
  || network === 'bsctestnet-fork'
  || network === 'hecotestnet'
  || network === 'okextestnet'
  || network === 'polygontestnet'
  || network === 'avaxtestnet'
  || network === 'avaxtestnet-fork'
  || network === 'auroratestnet'
  || network === 'kavatestnet'
  || network === 'skaletestnet') {
    let storage = await NFTStorage.deployed();
    let cbkLand = await upgradeProxy(CBKLand.address, CBKLand, { deployer });
    let cbkLandProxy = await deployProxy(CBKLandBridgeProxyContract, [storage.address, cbkLand.address], { deployer });
    
    await storage.setProxyContract(cbkLand.address, cbkLandProxy.address, true);
    
    let cbkLandGM = await cbkLand.GAME_ADMIN();
    let cbkLandProxyGM = await cbkLandProxy.GAME_ADMIN();
    
    await cbkLand.grantRole(cbkLandGM, cbkLandProxy.address);

    await cbkLandProxy.grantRole(cbkLandProxyGM, storage.address);
    
    await storage.allowToken(cbkLand.address);
  }
};