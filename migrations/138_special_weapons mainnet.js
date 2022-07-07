const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const Weapons = artifacts.require("Weapons");
const Promos = artifacts.require("Promos");
const SafeRandoms = artifacts.require("SafeRandoms");
const SpecialWeaponsManager = artifacts.require("SpecialWeaponsManager");
const CryptoBlades = artifacts.require("CryptoBlades");
const BurningManager = artifacts.require("BurningManager");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");
const PvpArena = artifacts.require("PvpArena");
const NFTStorage = artifacts.require("NFTStorage");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const SkillStakingRewardsUpgradeable90 = artifacts.require("SkillStakingRewardsUpgradeable90");
const SkillStakingRewardsUpgradeable180 = artifacts.require("SkillStakingRewardsUpgradeable180");

module.exports = async function (deployer, network) {
  if (network === 'bscmainnet'
    || network === 'bscmainnet-fork'
    || network === 'hecomainnet'
    || network === 'okexmainnet'
    || network === 'polygonmainnet'
    || network === 'avaxmainnet'
    || network === 'avaxmainnet-fork'
    || network === 'auroramainnet'
    || network === 'skalemainnet'
    || network === 'kavamainnet') {
    let weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
    let promos = await Promos.deployed();
    let safeRandoms = await SafeRandoms.deployed();
    let priceOracle = await BasicPriceOracle.deployed();
    let game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    let specialWeaponsManager = await deployProxy(SpecialWeaponsManager, [promos.address, weapons.address, safeRandoms.address, game.address, priceOracle.address], { deployer });

    await game.migrateTo_e1fe97c(specialWeaponsManager.address);

    let burningManager = await upgradeProxy(BurningManager.address, BurningManager, { deployer });
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

    // 1,2,3 = shard forge costs
    // 4,5,6 = skill forge costs in usd
    // 10 = shard conversion denominator
    // 11 = shards per 1 SKILL staking per day in wei
    await specialWeaponsManager.setVars([1, 2, 3, 4, 5, 6, 10, 11], ['333', '433', '666', '750', '1000', '1500', '3', '100000000000000000']);

    await upgradeProxy(PvpArena.address, PvpArena, { deployer });
    await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
  
    let skillStakingRewardsUpgradeable, skillStakingRewardsUpgradeable90, skillStakingRewardsUpgradeable180;
    skillStakingRewardsUpgradeable = await upgradeProxy(SkillStakingRewardsUpgradeable.address, SkillStakingRewardsUpgradeable, { deployer });
    await skillStakingRewardsUpgradeable.migrateTo_e1fe97c(specialWeaponsManager.address);
    await specialWeaponsManager.grantRole(swm_GAME_ADMIN, skillStakingRewardsUpgradeable.address);
    if(network === 'bscmainnet' || network === 'bscmainnet-fork') {
      skillStakingRewardsUpgradeable90 = await upgradeProxy(SkillStakingRewardsUpgradeable90.address, SkillStakingRewardsUpgradeable90, { deployer });
      skillStakingRewardsUpgradeable180 = await upgradeProxy(SkillStakingRewardsUpgradeable180.address, SkillStakingRewardsUpgradeable180, { deployer });
      await skillStakingRewardsUpgradeable90.migrateTo_e1fe97c(specialWeaponsManager.address);
      await skillStakingRewardsUpgradeable180.migrateTo_e1fe97c(specialWeaponsManager.address);
      
      await specialWeaponsManager.grantRole(swm_GAME_ADMIN, skillStakingRewardsUpgradeable90.address);
      await specialWeaponsManager.grantRole(swm_GAME_ADMIN, skillStakingRewardsUpgradeable180.address);
    }
  }
};