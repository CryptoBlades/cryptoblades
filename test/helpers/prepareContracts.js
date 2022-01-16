const web3 = require('web3');

const SkillToken = artifacts.require('SkillToken');
const ExperimentToken = artifacts.require('ExperimentToken');
const ExperimentToken2 = artifacts.require('ExperimentToken2');
const SkillStakingRewardsUpgradeable = artifacts.require('SkillStakingRewardsUpgradeable');
const LPStakingRewardsUpgradeable = artifacts.require('LPStakingRewardsUpgradeable');
const LP2StakingRewardsUpgradeable = artifacts.require('LP2StakingRewardsUpgradeable');
const PvpArena = artifacts.require('PvpArena');
const BasicPriceOracle = artifacts.require('BasicPriceOracle');
const DummyRandoms = artifacts.require('DummyRandoms');
const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');
const CryptoBlades = artifacts.require('CryptoBlades');
const NFTMarket = artifacts.require('NFTMarket');
const RaidBasic = artifacts.require('RaidBasic');
const Promos = artifacts.require('Promos');
const Blacksmith = artifacts.require('Blacksmith');
const Shields = artifacts.require('Shields');
const CharacterRenameTagConsumables = artifacts.require('CharacterRenameTagConsumables');
const WeaponRenameTagConsumables = artifacts.require('WeaponRenameTagConsumables');
const CharacterFireTraitChangeConsumables = artifacts.require('CharacterFireTraitChangeConsumables');
const CharacterEarthTraitChangeConsumables = artifacts.require('CharacterEarthTraitChangeConsumables');
const CharacterWaterTraitChangeConsumables = artifacts.require('CharacterWaterTraitChangeConsumables');
const CharacterLightningTraitChangeConsumables = artifacts.require('CharacterLightningTraitChangeConsumables');
const Raid1 = artifacts.require('Raid1');

async function prepareContracts(accounts) {
  const skillToken = await SkillToken.new();
  const characters = await Characters.new();
  const weapons = await Weapons.new();
  const shields = await Shields.new();
  const pvpArena = await PvpArena.new();
  const priceOracle = await BasicPriceOracle.new();
  const randoms = await DummyRandoms.new();
  const expToken = await ExperimentToken.new();
  const expToken2 = await ExperimentToken2.new();
  const skillStakingRewards = await SkillStakingRewardsUpgradeable.new();
  const lpStakingRewards = await LPStakingRewardsUpgradeable.new();
  const lp2StakingRewards = await LP2StakingRewardsUpgradeable.new();
  const blacksmith = await Blacksmith.new();
  const game = await CryptoBlades.new();
  const raid = await RaidBasic.new();
  const nftMarket = await NFTMarket.new();
  const raid1 = await Raid1.new();
  const promos = await Promos.new();
  const characterRenameTagConsumables = await CharacterRenameTagConsumables.new();
  const characterFireTraitChangeConsumables = await CharacterFireTraitChangeConsumables.new();
  const characterEarthTraitChangeConsumables = await CharacterEarthTraitChangeConsumables.new();
  const characterWaterTraitChangeConsumables = await CharacterWaterTraitChangeConsumables.new();
  const characterLightningTraitChangeConsumables = await CharacterLightningTraitChangeConsumables.new();
  const weaponRenameTagConsumables = await WeaponRenameTagConsumables.new();

  await shields.initialize();
  await skillStakingRewards.initialize(accounts[0], accounts[0], skillToken.address, skillToken.address, 60);
  await lpStakingRewards.initialize(accounts[0], accounts[0], skillToken.address, skillToken.address, 60);
  await lp2StakingRewards.initialize(accounts[0], accounts[0], skillToken.address, skillToken.address, 60);
  await priceOracle.initialize();
  await characters.initialize();
  await weapons.initialize();
  await blacksmith.initialize(weapons.address, randoms.address);
  await game.initialize(skillToken.address, characters.address, weapons.address, priceOracle.address, randoms.address);
  await raid.initialize(game.address);
  await nftMarket.initialize(skillToken.address, game.address);
  await raid1.initialize(game.address);
  await pvpArena.initialize(game.address, shields.address, randoms.address);
  await promos.initialize();
  await weaponRenameTagConsumables.initialize(weapons.address);
  await randoms.initialize();

  await skillToken.transferFrom(skillToken.address, accounts[0], web3.utils.toWei('1', 'kether')); // 1000 skill, test token value is $5 usd
  await expToken.transferFrom(expToken.address, accounts[0], web3.utils.toWei('599', 'ether'));
  await expToken2.transferFrom(expToken2.address, accounts[0], web3.utils.toWei('699', 'ether'));

  const charas_GAME_ADMIN = await characters.GAME_ADMIN();
  const weps_GAME_ADMIN = await weapons.GAME_ADMIN();
  const shields_GAME_ADMIN = await shields.GAME_ADMIN();
  const GAME_ADMIN = await game.GAME_ADMIN();

  if (typeof randoms.setMain === 'function') {
    await randoms.setMain(game.address);
  }

  await skillToken.transferFrom(skillToken.address, game.address, web3.utils.toWei('0.5', 'mether'));
  await priceOracle.setCurrentPrice(web3.utils.toWei('0.2', 'ether')); // 1/5 SKILL per USD, AKA 5 USD per SKILL

  characterRenameTagConsumables.initialize(characters.address);
  characterFireTraitChangeConsumables.initialize(characters.address);
  characterEarthTraitChangeConsumables.initialize(characters.address);
  characterWaterTraitChangeConsumables.initialize(characters.address);
  characterLightningTraitChangeConsumables.initialize(characters.address);

  const pvpArena_GAME_ADMIN = await pvpArena.GAME_ADMIN();
  const promos_GAME_ADMIN = await promos.GAME_ADMIN();

  await pvpArena.grantRole(pvpArena_GAME_ADMIN, game.address);
  await pvpArena.grantRole(pvpArena_GAME_ADMIN, characters.address);
  await characters.grantRole(charas_GAME_ADMIN, game.address);
  await characters.grantRole(charas_GAME_ADMIN, pvpArena.address);

  await weapons.grantRole(weps_GAME_ADMIN, game.address);
  await weapons.grantRole(weps_GAME_ADMIN, pvpArena.address);
  await shields.grantRole(shields_GAME_ADMIN, pvpArena.address);
  await promos.grantRole(promos_GAME_ADMIN, game.address);
  await promos.grantRole(promos_GAME_ADMIN, characters.address);
  await game.grantRole(GAME_ADMIN, raid.address);
  await game.grantRole(GAME_ADMIN, blacksmith.address);

  await weapons.migrateTo_e55d8c5();
  await weapons.migrateTo_aa9da90();
  await weapons.migrateTo_951a020();
  await weapons.migrateTo_surprise(promos.address);

  await characters.migrateTo_1ee400a();
  await characters.migrateTo_951a020();
  await characters.migrateTo_ef994e2(promos.address);
  await characters.migrateTo_b627f23();

  await shields.migrateTo_surprise(promos.address);

  await game.migrateTo_ef994e2(promos.address);
  await game.migrateTo_23b3a8b(skillStakingRewards.address);
  await game.migrateTo_801f279();
  await game.migrateTo_60872c8(blacksmith.address);

  await blacksmith.migrateRandoms(randoms.address);
  await blacksmith.migrateTo_61c10da(shields.address, game.address);
  await blacksmith.migrateTo_16884dd(
    characterRenameTagConsumables.address,
    weaponRenameTagConsumables.address,
    characterFireTraitChangeConsumables.address,
    characterEarthTraitChangeConsumables.address,
    characterWaterTraitChangeConsumables.address,
    characterLightningTraitChangeConsumables.address
  );

  return {
    skillToken,
    characters,
    weapons,
    shields,
    pvpArena,
    priceOracle,
    randoms,
    expToken,
    expToken2,
    skillStakingRewards,
    lpStakingRewards,
    lp2StakingRewards,
    blacksmith,
    game,
    raid,
    nftMarket,
    raid1,
    promos,
    characterRenameTagConsumables,
    characterFireTraitChangeConsumables,
    characterEarthTraitChangeConsumables,
    characterWaterTraitChangeConsumables,
    characterLightningTraitChangeConsumables,
    weaponRenameTagConsumables,
  };
}

module.exports = prepareContracts;
