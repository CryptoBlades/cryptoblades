const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');


const NFTStorage = artifacts.require("NFTStorage");
const Shields = artifacts.require("Shields");
const Weapons = artifacts.require("Weapons");
const WeaponCosmetics = artifacts.require("WeaponCosmetics");
const WeaponRenameTagConsumables = artifacts.require("WeaponRenameTagConsumables");
const Characters = artifacts.require("Characters");
const CharacterCosmetics = artifacts.require("CharacterCosmetics");
const CharacterRenameTagConsumables = artifacts.require("CharacterRenameTagConsumables");

module.exports = async function (deployer, network, accounts) {
	
  const weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
  const weaponCosmetics = await upgradeProxy(WeaponCosmetics.address, WeaponCosmetics, { deployer });
  const weaponRenameTagConsumables = await upgradeProxy(WeaponRenameTagConsumables.address, WeaponRenameTagConsumables, { deployer });
  
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });
  const characterCosmetics = await upgradeProxy(CharacterCosmetics.address, CharacterCosmetics, { deployer });
  const characterRenameTagConsumables = await upgradeProxy(CharacterRenameTagConsumables.address, CharacterRenameTagConsumables, { deployer });
  
  const nftStorage = await deployProxy(NFTStorage, [weapons.address, characters.address, weaponRenameTagConsumables.address, characterRenameTagConsumables.address, weaponCosmetics.address, characterCosmetics.address], { deployer });

  
  await nftStorage.allowToken(weapons.address);
  await nftStorage.allowToken(characters.address);
  
  const weapons_MINTER_ROLE = await weapons.MINTER_ROLE();
  await weapons.grantRole(weapons_MINTER_ROLE, nftStorage.address);
  
  const weaponCosmetics_GAME_ADMIN = await weaponCosmetics.GAME_ADMIN();
  await weaponCosmetics.grantRole(weaponCosmetics_GAME_ADMIN, nftStorage.address);
  
  const weaponRenameTagConsumables_GAME_ADMIN = await weaponRenameTagConsumables.GAME_ADMIN();
  await weaponRenameTagConsumables.grantRole(weaponRenameTagConsumables_GAME_ADMIN, nftStorage.address);
  
  const characters_MINTER_ROLE = await characters.MINTER_ROLE();
  await characters.grantRole(characters_MINTER_ROLE, nftStorage.address);
  
  const characterCosmetics_GAME_ADMIN = await characterCosmetics.GAME_ADMIN();
  await characterCosmetics.grantRole(characterCosmetics_GAME_ADMIN, nftStorage.address);
  
  const characterRenameTagConsumables_GAME_ADMIN = await characterRenameTagConsumables.GAME_ADMIN();
  await characterRenameTagConsumables.grantRole(characterRenameTagConsumables_GAME_ADMIN, nftStorage.address);
  
  const characters_NO_OWNED_LIMIT = await characters.NO_OWNED_LIMIT();
  await characters.grantRole(characters_NO_OWNED_LIMIT, nftStorage.address);
};