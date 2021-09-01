const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const Weapons = artifacts.require("Weapons");
const WeaponCosmetics = artifacts.require("WeaponCosmetics");
const Characters = artifacts.require("Characters");
const CharacterCosmetics = artifacts.require("CharacterCosmetics");

module.exports = async function (deployer, network, accounts) {
  const weapons = await Weapons.deployed();
  const weapons_GAME_ADMIN = await weapons.GAME_ADMIN();
  
  const weaponCosmetics = await deployProxy(WeaponCosmetics, [weapons.address], { deployer });
  
  const characters = await Characters.deployed();
  const characters_GAME_ADMIN = await characters.GAME_ADMIN();

  const charactersCosmetics = await deployProxy(CharacterCosmetics, [characters.address], { deployer });
  
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await blacksmith.migrateTo_eefb9b1(weaponCosmetics.address, charactersCosmetics.address);

  await weapons.grantRole(weapons_GAME_ADMIN, weaponCosmetics.address);
  
  const weaponCosmetics_GAME_ADMIN = await weaponCosmetics.GAME_ADMIN();
  await weaponCosmetics.grantRole(weaponCosmetics_GAME_ADMIN, blacksmith.address);
  
  await characters.grantRole(characters_GAME_ADMIN, charactersCosmetics.address);
  
  const charactersCosmetics_GAME_ADMIN = await charactersCosmetics.GAME_ADMIN();
  await charactersCosmetics.grantRole(charactersCosmetics_GAME_ADMIN, blacksmith.address);
};