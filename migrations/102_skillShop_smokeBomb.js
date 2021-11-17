const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const Characters = artifacts.require("Characters");
const SmokeBombConsumables = artifacts.require("SmokeBombConsumables");

module.exports = async function (deployer, network, accounts) { 
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });
  const characters_GAME_ADMIN = await characters.GAME_ADMIN();
  
  const smokeBombConsumables = await deployProxy(SmokeBombConsumables, [Characters.address], { deployer });
  
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await blacksmith.migrateTo_cdd5968(smokeBombConsumables.address);
  
  const smokeBombConsumable_GAME_ADMIN = await smokeBombConsumables.GAME_ADMIN();
  await smokeBombConsumables.grantRole(smokeBombConsumable_GAME_ADMIN, blacksmith.address);
  
  await characters.grantRole(characters_GAME_ADMIN, smokeBombConsumables.address);
};