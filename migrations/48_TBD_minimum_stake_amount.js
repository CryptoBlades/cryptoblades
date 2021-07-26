const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");
const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");

module.exports = async function (deployer, network, accounts) {
  const skillSr = await upgradeProxy(SkillStakingRewardsUpgradeable.address, SkillStakingRewardsUpgradeable, { deployer, unsafeAllowRenames: true });
  // 0.001 minimumStakeAmount
  await skillSr.migrateTo_8cb6e70('1000000000000000');

  const lpSr = await upgradeProxy(LPStakingRewardsUpgradeable.address, LPStakingRewardsUpgradeable, { deployer });
  // 0.001 minimumStakeAmount
  await lpSr.migrateTo_8cb6e70('1000000000000000');

  const lp2Sr = await upgradeProxy(LP2StakingRewardsUpgradeable.address, LP2StakingRewardsUpgradeable, { deployer });
  // 0.001 minimumStakeAmount
  await lp2Sr.migrateTo_8cb6e70('1000000000000000');
};

