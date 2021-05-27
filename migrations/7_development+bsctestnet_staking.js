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

    await deployProxy(SkillStakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, token.address, 60], { deployer });
    await deployProxy(LPStakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, expToken.address, 0], { deployer });
    await deployProxy(LP2StakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, expToken2.address, 0], { deployer });
  }
};
