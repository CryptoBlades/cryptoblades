const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Blacksmith = artifacts.require("Blacksmith");
const Characters = artifacts.require("Characters");
const SmokeBombConsumables = artifacts.require("SmokeBombConsumables");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });
  const characters_GAME_ADMIN = await characters.GAME_ADMIN();
  
  const game = await CryptoBlades.deployed();
  const randomsAddr = await game.randoms();
  const smokeBombConsumables = await deployProxy(SmokeBombConsumables, [Characters.address, randomsAddr], { deployer });
  
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await blacksmith.migrateTo_cdd5968(smokeBombConsumables.address);
  
  const smokeBombConsumable_GAME_ADMIN = await smokeBombConsumables.GAME_ADMIN();
  await smokeBombConsumables.grantRole(smokeBombConsumable_GAME_ADMIN, blacksmith.address);
  
  await characters.grantRole(characters_GAME_ADMIN, smokeBombConsumables.address);
};