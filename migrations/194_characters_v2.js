const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const Characters = artifacts.require("Characters");
const CryptoBlades = artifacts.require("CryptoBlades");
const Treasury = artifacts.require("Treasury");
const ValorToken = artifacts.require("ValorToken");

const ERC20Bridge = artifacts.require("ERC20Bridge");
const ValorERC20BridgeProxyContract = artifacts.require("ValorERC20BridgeProxyContract");
const Promos = artifacts.require("Promos");

const NFTStorage = artifacts.require("NFTStorage");
const CharactersBridgeProxyContract = artifacts.require("CharactersBridgeProxyContract");
const ShieldBridgeProxyContract = artifacts.require("ShieldBridgeProxyContract");
const WeaponBridgeProxyContract = artifacts.require("WeaponBridgeProxyContract");

module.exports = async function (deployer) {
  await upgradeProxy(Characters.address, Characters, { deployer });
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(Treasury.address, Treasury, { deployer });
  let valorToken = await deployProxy(ValorToken, [], { deployer });
  
  
  // Valor bridging
  let promos = await Promos.deployed();
  let erc20Bridge = await ERC20Bridge.deployed();
  let valorProxy = await deployProxy(ValorERC20BridgeProxyContract, [promos.address], { deployer }); 
  await erc20Bridge.setProxyContract(valorToken.address, valorProxy.address, true);
  
  // Gen 2 support (can bridge method in proxies)
   await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
   await upgradeProxy(CharactersBridgeProxyContract.address, CharactersBridgeProxyContract, { deployer });
   await upgradeProxy(ShieldBridgeProxyContract.address, ShieldBridgeProxyContract, { deployer });
   await upgradeProxy(WeaponBridgeProxyContract.address, WeaponBridgeProxyContract, { deployer });
};