const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const Weapons = artifacts.require("Weapons");
const WeaponCosmetics = artifacts.require("WeaponCosmetics");

module.exports = async function (deployer, network, accounts) {
  const weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
  const weapons_GAME_ADMIN = await weapons.GAME_ADMIN();

  const weaponCosmetics = await deployProxy(WeaponCosmetics, [Weapons.address], { deployer });

  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await blacksmith.migrateTo_eefb9b1(weaponCosmetics.address);

  await weapons.grantRole(weapons_GAME_ADMIN, weaponCosmetics.address);
  
  const weaponCosmetics_GAME_ADMIN = await weaponCosmetics.GAME_ADMIN();
  await weaponCosmetics.grantRole(weaponCosmetics_GAME_ADMIN, blacksmith.address);
};