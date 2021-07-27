const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");
const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");
const NFTMarket = artifacts.require("NFTMarket");
const Promos = artifacts.require("Promos");
const RaidBasic = artifacts.require("RaidBasic");
const WaxBridge = artifacts.require("WaxBridge");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(Characters.address, Characters, { deployer });
  await upgradeProxy(Weapons.address, Weapons, { deployer });
  await upgradeProxy(SkillStakingRewardsUpgradeable.address, SkillStakingRewardsUpgradeable, { deployer });
  await upgradeProxy(LPStakingRewardsUpgradeable.address, LPStakingRewardsUpgradeable, { deployer });
  await upgradeProxy(LP2StakingRewardsUpgradeable.address, LP2StakingRewardsUpgradeable, { deployer });
  await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
  await upgradeProxy(Promos.address, Promos, { deployer });
  await upgradeProxy(RaidBasic.address, RaidBasic, { deployer });
  await upgradeProxy(WaxBridge.address, WaxBridge, { deployer });
};
