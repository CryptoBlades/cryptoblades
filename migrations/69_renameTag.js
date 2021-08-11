const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const CharacterRenameTagConsumables = artifacts.require("CharacterRenameTagConsumables");
const WeaponRenameTagConsumables = artifacts.require("WeaponRenameTagConsumables");
const CharacterFireTraitChangeConsumables = artifacts.require("CharacterFireTraitChangeConsumables");
const CharacterEarthTraitChangeConsumables = artifacts.require("CharacterEarthTraitChangeConsumables");
const CharacterWaterTraitChangeConsumables = artifacts.require("CharacterWaterTraitChangeConsumables");
const CharacterLightningTraitChangeConsumables = artifacts.require("CharacterLightningTraitChangeConsumables");

module.exports = async function (deployer, network, accounts) {
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });
  const characters_GAME_ADMIN = await characters.GAME_ADMIN();

  const characterRenameTagConsumables = await deployProxy(CharacterRenameTagConsumables, [Characters.address], { deployer });
  const weaponRenameTagConsumables = await deployProxy(WeaponRenameTagConsumables, [Weapons.address], { deployer });
  const characterFireTraitChangeConsumables = await deployProxy(CharacterFireTraitChangeConsumables, [Characters.address], { deployer });
  const characterEarthTraitChangeConsumables = await deployProxy(CharacterEarthTraitChangeConsumables, [Characters.address], { deployer });
  const characterWaterTraitChangeConsumables = await deployProxy(CharacterWaterTraitChangeConsumables, [Characters.address], { deployer });
  const characterLightningTraitChangeConsumables = await deployProxy(CharacterLightningTraitChangeConsumables, [Characters.address], { deployer });

  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await blacksmith.migrateTo_16884dd(characterRenameTagConsumables.address, weaponRenameTagConsumables.address,
    characterFireTraitChangeConsumables.address, characterEarthTraitChangeConsumables.address,
    characterWaterTraitChangeConsumables.address, characterLightningTraitChangeConsumables.address);

  const characterRenameTagConsumables_GAME_ADMIN = await characterRenameTagConsumables.GAME_ADMIN();
  await characterRenameTagConsumables.grantRole(characterRenameTagConsumables_GAME_ADMIN, blacksmith.address);
  
  const weaponRenameTagConsumables_GAME_ADMIN = await weaponRenameTagConsumables.GAME_ADMIN();
  await weaponRenameTagConsumables.grantRole(weaponRenameTagConsumables_GAME_ADMIN, blacksmith.address);

  const characterFireTraitChangeConsumables_GAME_ADMIN = await characterFireTraitChangeConsumables.GAME_ADMIN();
  await characterFireTraitChangeConsumables.grantRole(characterFireTraitChangeConsumables_GAME_ADMIN, blacksmith.address);

  const characterEarthTraitChangeConsumables_GAME_ADMIN = await characterEarthTraitChangeConsumables.GAME_ADMIN();
  await characterEarthTraitChangeConsumables.grantRole(characterEarthTraitChangeConsumables_GAME_ADMIN, blacksmith.address);

  const characterWaterTraitChangeConsumables_GAME_ADMIN = await characterWaterTraitChangeConsumables.GAME_ADMIN();
  await characterWaterTraitChangeConsumables.grantRole(characterWaterTraitChangeConsumables_GAME_ADMIN, blacksmith.address);

  const characterLightningTraitChangeConsumables_GAME_ADMIN = await characterLightningTraitChangeConsumables.GAME_ADMIN();
  await characterLightningTraitChangeConsumables.grantRole(characterLightningTraitChangeConsumables_GAME_ADMIN, blacksmith.address);

  await characters.grantRole(characters_GAME_ADMIN, characterFireTraitChangeConsumables.address);
  await characters.grantRole(characters_GAME_ADMIN, characterEarthTraitChangeConsumables.address);
  await characters.grantRole(characters_GAME_ADMIN, characterWaterTraitChangeConsumables.address);
  await characters.grantRole(characters_GAME_ADMIN, characterLightningTraitChangeConsumables.address);
};