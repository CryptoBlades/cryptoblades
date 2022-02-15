const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const Weapons = artifacts.require("Weapons");
const Promos = artifacts.require("Promos");
const SafeRandoms = artifacts.require("SafeRandoms");
const SpecialWeaponsManager = artifacts.require("SpecialWeaponsManager");
const CryptoBlades = artifacts.require("CryptoBlades");
const BurningManager = artifacts.require("BurningManager");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");

module.exports = async function (deployer) {
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

  await specialWeaponsManager.setVars([1, 2, 3, 5], ['7', '15', '20', '3']);
};