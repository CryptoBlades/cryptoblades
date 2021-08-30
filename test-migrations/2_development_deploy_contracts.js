const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const assert = require("assert");
const SkillToken = artifacts.require("SkillToken");
const ExperimentToken = artifacts.require("ExperimentToken");
const ExperimentToken2 = artifacts.require("ExperimentToken2");
const SkillStakingRewardsUpgradeable = artifacts.require(
  "SkillStakingRewardsUpgradeable"
);
const LPStakingRewardsUpgradeable = artifacts.require(
  "LPStakingRewardsUpgradeable"
);
const LP2StakingRewardsUpgradeable = artifacts.require(
  "LP2StakingRewardsUpgradeable"
);
const PvpArena = artifacts.require("PvpArena");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");
const DummyRandoms = artifacts.require("DummyRandoms");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const CryptoBlades = artifacts.require("CryptoBlades");
const NFTMarket = artifacts.require("NFTMarket");
const RaidBasic = artifacts.require("RaidBasic");
const Promos = artifacts.require("Promos");
const Blacksmith = artifacts.require("Blacksmith");
const Shields = artifacts.require("Shields");
const CharacterRenameTagConsumables = artifacts.require("CharacterRenameTagConsumables");
const WeaponRenameTagConsumables = artifacts.require("WeaponRenameTagConsumables");
const CharacterFireTraitChangeConsumables = artifacts.require("CharacterFireTraitChangeConsumables");
const CharacterEarthTraitChangeConsumables = artifacts.require("CharacterEarthTraitChangeConsumables");
const CharacterWaterTraitChangeConsumables = artifacts.require("CharacterWaterTraitChangeConsumables");
const CharacterLightningTraitChangeConsumables = artifacts.require("CharacterLightningTraitChangeConsumables");
const Raid1= artifacts.require("Raid1");

module.exports = async function (deployer, network, accounts) {
  let randoms, skillToken;

  await deployer.deploy(SkillToken);
  const token = await SkillToken.deployed();

  await deployer.deploy(ExperimentToken);
  const expToken = await ExperimentToken.deployed();

  await deployer.deploy(ExperimentToken2);
  const expToken2 = await ExperimentToken2.deployed();

  const shields = await deployProxy(Shields, [], { deployer });

  // token setup for local dev
  await token.transferFrom(
    token.address,
    accounts[0],
    web3.utils.toWei("1", "kether")
  ); // 1000 skill, test token value is $5 usd
  await expToken.transferFrom(
    expToken.address,
    accounts[0],
    web3.utils.toWei("599", "ether")
  );
  await expToken2.transferFrom(
    expToken2.address,
    accounts[0],
    web3.utils.toWei("699", "ether")
  );

  const skillStakingRewards = await deployProxy(
    SkillStakingRewardsUpgradeable,
    [accounts[0], accounts[0], token.address, token.address, 60],
    { deployer }
  );
  const lpStakingRewards = await deployProxy(
    LPStakingRewardsUpgradeable,
    [accounts[0], accounts[0], token.address, expToken.address, 0],
    { deployer }
  );
  const lp2StakingRewards = await deployProxy(
    LP2StakingRewardsUpgradeable,
    [accounts[0], accounts[0], token.address, expToken2.address, 0],
    { deployer }
  );

  randoms = await deployProxy(DummyRandoms, [], { deployer });
  skillToken = await SkillToken.deployed();

  assert(skillToken != null, "Expected skillToken to be set to a contract");
  assert(randoms != null, "Expected random to be set to a contract");

  const priceOracle = await deployProxy(BasicPriceOracle, [], { deployer });
  const charas = await deployProxy(Characters, [], { deployer });
  const weps = await deployProxy(Weapons, [], { deployer });
  const blacksmith = await deployProxy(Blacksmith, [weps.address, randoms.address], { deployer });

  const game = await deployProxy(
    CryptoBlades,
    [
      skillToken.address,
      charas.address,
      weps.address,
      priceOracle.address,
      randoms.address,
    ],
    { deployer }
  );

  const charas_GAME_ADMIN = await charas.GAME_ADMIN();
  const weps_GAME_ADMIN = await weps.GAME_ADMIN();
  
  if (typeof randoms.setMain === "function") {
    await randoms.setMain(game.address);
  }
  
  const raid = await deployProxy(RaidBasic, [game.address], { deployer });  
  const GAME_ADMIN = await game.GAME_ADMIN();

  await token.transferFrom(
    token.address,
    game.address,
    web3.utils.toWei("0.5", "mether")
    ); // megaether
    
    await priceOracle.setCurrentPrice(web3.utils.toWei("0.2", "ether")); // 1/5 SKILL per USD, AKA 5 USD per SKILL
    
    await deployProxy(NFTMarket, [SkillToken.address, CryptoBlades.address], {
      deployer,
    });
    
    const raid1= await deployProxy(Raid1,[game.address],{deployer});
    const pvpArena = await deployProxy(PvpArena, [game.address,shields.address,raid1.address], { deployer });
    const promos = await deployProxy(Promos, [], { deployer });
    const characterRenameTagConsumables = await deployProxy(CharacterRenameTagConsumables, [charas.address], { deployer });
    const weaponRenameTagConsumables = await deployProxy(WeaponRenameTagConsumables, [weps.address], { deployer });
    const characterFireTraitChangeConsumables = await deployProxy(CharacterFireTraitChangeConsumables, [charas.address], { deployer });
    const characterEarthTraitChangeConsumables = await deployProxy(CharacterEarthTraitChangeConsumables, [charas.address], { deployer });
    const characterWaterTraitChangeConsumables = await deployProxy(CharacterWaterTraitChangeConsumables, [charas.address], { deployer });
    const characterLightningTraitChangeConsumables = await deployProxy(CharacterLightningTraitChangeConsumables, [charas.address], { deployer });
    
    const pvpArena_GAME_ADMIN = await pvpArena.GAME_ADMIN();
    const promos_GAME_ADMIN = await promos.GAME_ADMIN();
    
    await pvpArena.grantRole(pvpArena_GAME_ADMIN, game.address);
    await charas.grantRole(charas_GAME_ADMIN, game.address);
    await weps.grantRole(weps_GAME_ADMIN, game.address);
    await promos.grantRole(promos_GAME_ADMIN, game.address);
    await promos.grantRole(promos_GAME_ADMIN, charas.address);

    await game.grantRole(GAME_ADMIN, raid.address);
    await game.grantRole(GAME_ADMIN, blacksmith.address);
    
    await weps.migrateTo_e55d8c5();
    await weps.migrateTo_aa9da90();
    await weps.migrateTo_951a020();
    await weps.migrateTo_surprise(promos.address);
    
    await charas.migrateTo_1ee400a();
    await charas.migrateTo_951a020();
    await charas.migrateTo_ef994e2(promos.address); 
    await charas.migrateTo_b627f23();
    
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
};
