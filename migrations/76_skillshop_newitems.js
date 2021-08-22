const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const Characters = artifacts.require("Characters");
const SmokeBombConsumables = artifacts.require("SmokeBombConsumables");
const ExpScrollConsumables = artifacts.require("ExpScrollConsumables");
const CryptoBlades = artifacts.require("CryptoBlades");
const CharacterRenameTagConsumables = artifacts.require("CharacterRenameTagConsumables");
const WeaponRenameTagConsumables = artifacts.require("WeaponRenameTagConsumables");
const CharacterFireTraitChangeConsumables = artifacts.require("CharacterFireTraitChangeConsumables");
const CharacterEarthTraitChangeConsumables = artifacts.require("CharacterEarthTraitChangeConsumables");
const CharacterWaterTraitChangeConsumables = artifacts.require("CharacterWaterTraitChangeConsumables");
const CharacterLightningTraitChangeConsumables = artifacts.require("CharacterLightningTraitChangeConsumables");

module.exports = async function (deployer, network, accounts) {
	
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(CharacterRenameTagConsumables.address, CharacterRenameTagConsumables, { deployer });
  await upgradeProxy(WeaponRenameTagConsumables.address, WeaponRenameTagConsumables, { deployer });
  await upgradeProxy(CharacterFireTraitChangeConsumables.address, CharacterFireTraitChangeConsumables, { deployer });
  await upgradeProxy(CharacterEarthTraitChangeConsumables.address, CharacterEarthTraitChangeConsumables, { deployer });
  await upgradeProxy(CharacterWaterTraitChangeConsumables.address, CharacterWaterTraitChangeConsumables, { deployer });
  await upgradeProxy(CharacterLightningTraitChangeConsumables.address, CharacterLightningTraitChangeConsumables, { deployer });
	
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });
  const characters_GAME_ADMIN = await characters.GAME_ADMIN();
  
  const game = await CryptoBlades.deployed();
  const randomsAddr = await game.randoms();
  const smokeBombConsumables = await deployProxy(SmokeBombConsumables, [Characters.address, randomsAddr], { deployer });

  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
	
  const smokeBombConsumable_GAME_ADMIN = await smokeBombConsumables.GAME_ADMIN();
  await smokeBombConsumables.grantRole(smokeBombConsumable_GAME_ADMIN, blacksmith.address);
 
  await characters.grantRole(characters_GAME_ADMIN, smokeBombConsumables.address);
  
  const expScrollConsumables = await deployProxy(ExpScrollConsumables, [Characters.address], { deployer });

  const expScrollConsumables_GAME_ADMIN = await expScrollConsumables.GAME_ADMIN();
  await expScrollConsumables.grantRole(expScrollConsumables_GAME_ADMIN, blacksmith.address);
 
  await characters.grantRole(characters_GAME_ADMIN, expScrollConsumables.address);
  
  await blacksmith.migrateTo_cdd5968(smokeBombConsumables.address, expScrollConsumables.address);

};