const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const JunkBridgeProxyContract = artifacts.require("JunkBridgeProxyContract");
const Junk = artifacts.require("Junk");

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
  || network === 'kavatestnet') {
    let storage = await NFTStorage.deployed();
    let junk = await upgradeProxy(Junk.address, Junk, { deployer });
    let junkProxy = await deployProxy(JunkBridgeProxyContract, [storage.address, junk.address], { deployer });
    
    await storage.setProxyContract(junk.address, junkProxy.address, true);
    
    let junkGM = await junk.GAME_ADMIN();
    let junkProxyGM = await junkProxy.GAME_ADMIN();
    
    await junk.grantRole(junkGM, junkProxy.address);

    await junkProxy.grantRole(junkProxyGM, storage.address);
    
    await storage.allowToken(junk.address);
	
    //await junkProxy.setEnabled(true); // on both testnet heco and testnet bsc
    //await storage.setChainSupportedForNFT(junk.address, [97], true); on testnet heco
    //await storage.setChainSupportedForNFT(junk.address, [256], true); on testnet bsc
  }
};