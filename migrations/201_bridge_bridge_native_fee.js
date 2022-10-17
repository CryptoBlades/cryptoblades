const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");

module.exports = async function (deployer, network) {
  const nftStorage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
  
  let fee = '0';
  

  if(network === 'bscmainnet' || network === 'bscmainnet-fork') {
        fee = '700000000000000';
  }
  

  if(network === 'hecomainnet') {
        fee = '700000000000000';
  }
  
  if(network === 'okexmainnet') {
        fee = '40000000000000';
  }
  
  if(network === 'polygonmainnet') {
        fee = '42000000000000';
  }
  
  
  if(network === 'skalemainnet') {
        fee = '0';
  }
  
  if(network === 'kavamainnet') {
        fee = '0';
  }
  
  if(network === 'auroramainnet') {
        fee = '20000000000000';
  }
  
   if (network === 'development' || network === 'development-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork' || network === 'hecotestnet'){
	   fee = '700000000000000';
   }
  

  await nftStorage.setRequestBridgeNativeFee(Characters.address, fee);
  await nftStorage.setRequestBridgeNativeFee(Weapons.address, fee);
  await nftStorage.setRequestBridgeNativeFee(Shields.address, fee);
};