const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const SkillToken = artifacts.require("SkillToken");
const ExperimentToken = artifacts.require("ExperimentToken");
const ExperimentToken2 = artifacts.require("ExperimentToken2");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const SkillStakingRewardsUpgradeable90 = artifacts.require("SkillStakingRewardsUpgradeable90");
const SkillStakingRewardsUpgradeable180 = artifacts.require("SkillStakingRewardsUpgradeable180");
const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");
const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");

module.exports = async function (deployer, network, accounts) {
  if (network === 'development' || network === 'development-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork' || network === 'hecotestnet' || network === 'okextestnet' || network === 'polygontestnet' || network === 'avaxtestnet' || network === 'avaxtestnet-fork' || network === 'auroratestnet' || network === 'kavatestnet' || network === 'skaletestnet' || network === 'coinextestnet' || network === 'metertestnet' || network === 'cronostestnet' || network === 'opsidetestnet') {
    const token = await SkillToken.deployed();
    const expToken = await ExperimentToken.deployed();
    const expToken2 = await ExperimentToken2.deployed();

    await deployProxy(SkillStakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, token.address, 60], { deployer });
    await deployProxy(SkillStakingRewardsUpgradeable90, [accounts[0], accounts[0], token.address, token.address, 60], { deployer });
    await deployProxy(SkillStakingRewardsUpgradeable180, [accounts[0], accounts[0], token.address, token.address, 60], { deployer });
    await deployProxy(LPStakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, expToken.address, 0], { deployer });
    await deployProxy(LP2StakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, expToken2.address, 0], { deployer });
  }
};
