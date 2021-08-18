const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");
const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(SkillStakingRewardsUpgradeable.address, SkillStakingRewardsUpgradeable, { deployer });
  await upgradeProxy(LPStakingRewardsUpgradeable.address, LPStakingRewardsUpgradeable, { deployer });
  await upgradeProxy(LP2StakingRewardsUpgradeable.address, LP2StakingRewardsUpgradeable, { deployer });

  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

  await game.migrateTo_6a97bd1();
};
