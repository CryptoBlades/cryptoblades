const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const SkillToken = artifacts.require("SkillToken");
const ExperimentToken = artifacts.require("ExperimentToken");
const ExperimentToken2 = artifacts.require("ExperimentToken2");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");
const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");

module.exports = async function (deployer, network, accounts) {
  if (network === 'development' || network === 'development-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork') {
    const token = await SkillToken.deployed();
    const expToken = await ExperimentToken.deployed();
    const expToken2 = await ExperimentToken2.deployed();

    // 0.001 minimumStakeAmount
    await deployProxy(SkillStakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, token.address, 1000000000000000, 60], { deployer });

    // 0.001 minimumStakeAmount
    await deployProxy(LPStakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, expToken.address, 1000000000000000, 0], { deployer });

    // 0.001 minimumStakeAmount
    await deployProxy(LP2StakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, expToken2.address, 1000000000000000, 0], { deployer });
  }
};
