const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const Weapons = artifacts.require("Weapons");
const Promos = artifacts.require("Promos");
const SafeRandoms = artifacts.require("SafeRandoms");
const SpecialWeaponsManager = artifacts.require("SpecialWeaponsManager");
const CryptoBlades = artifacts.require("CryptoBlades");
const BurningManager = artifacts.require("BurningManager");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");
const PvpArena = artifacts.require("PvpArena");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const SkillStakingRewardsUpgradeable90 = artifacts.require("SkillStakingRewardsUpgradeable90");
const SkillStakingRewardsUpgradeable180 = artifacts.require("SkillStakingRewardsUpgradeable180");

module.exports = async function (deployer, accounts, network) {
  let weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
  let promos = await upgradeProxy(Promos.address, Promos, { deployer });
  let safeRandoms = await SafeRandoms.deployed();
  let specialWeaponsManager = await deployProxy(SpecialWeaponsManager, [promos.address, weapons.address, safeRandoms.address], { deployer });

  let game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await game.migrateTo_e1fe97c(specialWeaponsManager.address);

  let burningManager = await upgradeProxy(BurningManager.address, BurningManager, { deployer });
  let priceOracle = await BasicPriceOracle.deployed();
  await burningManager.migrateTo_e1fe97c(weapons.address, priceOracle.address);

  let swm_GAME_ADMIN = await specialWeaponsManager.GAME_ADMIN();
  await specialWeaponsManager.grantRole(swm_GAME_ADMIN, game.address);

  let GAME_ADMIN = await game.GAME_ADMIN();
  await game.grantRole(GAME_ADMIN, specialWeaponsManager.address);

  let weps_GAME_ADMIN = await weapons.GAME_ADMIN();
  await weapons.grantRole(weps_GAME_ADMIN, specialWeaponsManager.address);
  await weapons.grantRole(weps_GAME_ADMIN, burningManager.address);

  let safe_randoms_GAME_ADMIN = await safeRandoms.GAME_ADMIN();
  await safeRandoms.grantRole(safe_randoms_GAME_ADMIN, specialWeaponsManager.address);

  await specialWeaponsManager.setVars([1, 2, 3, 5, 6], ['7', '15', '20', '3', '100000000000000000']);

  await upgradeProxy(PvpArena.address, PvpArena, { deployer });
 
  let skillStakingRewardsUpgradeable = await upgradeProxy(SkillStakingRewardsUpgradeable.address, SkillStakingRewardsUpgradeable, { deployer });
  await skillStakingRewardsUpgradeable.migrateTo_e1fe97c(specialWeaponsManager.address);
  let skillStakingRewardsUpgradeable90 = await upgradeProxy(SkillStakingRewardsUpgradeable90.address, SkillStakingRewardsUpgradeable90, { deployer });
  let skillStakingRewardsUpgradeable180 = await upgradeProxy(SkillStakingRewardsUpgradeable180.address, SkillStakingRewardsUpgradeable180, { deployer });

  await specialWeaponsManager.grantRole(swm_GAME_ADMIN, skillStakingRewardsUpgradeable.address);
  await specialWeaponsManager.grantRole(swm_GAME_ADMIN, skillStakingRewardsUpgradeable90.address);
  await specialWeaponsManager.grantRole(swm_GAME_ADMIN, skillStakingRewardsUpgradeable180.address);
};