const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const CharactersBridgeProxyContract = artifacts.require("CharactersBridgeProxyContract");
const Characters = artifacts.require("Characters");


module.exports = async function (deployer, network) {
  await upgradeProxy(CharactersBridgeProxyContract.address, CharactersBridgeProxyContract, { deployer }); 
  await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
  let characters = await upgradeProxy(Characters.address, Characters, { deployer });
  await characters.setSecondsPerStamina(300);
  await characters.grantRole(await characters.GAME_ADMIN(), NFTStorage.address);
};