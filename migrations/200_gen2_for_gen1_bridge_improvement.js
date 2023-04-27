const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const CharactersBridgeProxyContract = artifacts.require("CharactersBridgeProxyContract");
const Characters = artifacts.require("Characters");


module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CharactersBridgeProxyContract.address, CharactersBridgeProxyContract, { deployer }); 
  await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
  let characters = await upgradeProxy(Characters.address, Characters, { deployer });
  let charactersGA = await characters.GAME_ADMIN();
  await characters.grantRole(charactersGA, accounts[0]);
  await characters.setSecondsPerStamina(300);
  await characters.grantRole(charactersGA, NFTStorage.address);
};