const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Blacksmith = artifacts.require("Blacksmith");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const CharacterRenameTagConsumables = artifacts.require("CharacterRenameTagConsumables");
const WeaponRenameTagConsumables = artifacts.require("WeaponRenameTagConsumables");

module.exports = async function (deployer, network, accounts) {
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

  const characterRenameTagConsumables = await deployProxy(CharacterRenameTagConsumables, [Characters.address], { deployer });
  const weaponRenameTagConsumables = await deployProxy(WeaponRenameTagConsumables, [Weapons.address], { deployer });

  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await blacksmith.migrateTo_Something(characterRenameTagConsumables.address, weaponRenameTagConsumables.address);

  const characterRenameTagConsumables_GAME_ADMIN = await characterRenameTagConsumables.GAME_ADMIN();
  await characterRenameTagConsumables.grantRole(characterRenameTagConsumables_GAME_ADMIN, blacksmith.address);
  
  const weaponRenameTagConsumables_GAME_ADMIN = await weaponRenameTagConsumables.GAME_ADMIN();
  await weaponRenameTagConsumables.grantRole(weaponRenameTagConsumables_GAME_ADMIN, blacksmith.address);

  const game_GAME_ADMIN = await game.GAME_ADMIN();
  await game.grantRole(game_GAME_ADMIN, blacksmith.address);

};
