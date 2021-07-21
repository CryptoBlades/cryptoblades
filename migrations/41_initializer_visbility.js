const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");
const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const DummyRandoms = artifacts.require("DummyRandoms");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(LPStakingRewardsUpgradeable.address, LPStakingRewardsUpgradeable, { deployer });
  await upgradeProxy(LP2StakingRewardsUpgradeable.address, LP2StakingRewardsUpgradeable, { deployer });
  await upgradeProxy(SkillStakingRewardsUpgradeable.address, SkillStakingRewardsUpgradeable, { deployer });

  if (network === 'development' || network === 'development-fork') {
    await upgradeProxy(DummyRandoms.address, DummyRandoms, { deployer });
  }
};
