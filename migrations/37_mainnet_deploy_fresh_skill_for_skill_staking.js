const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");

module.exports = async function (deployer, network, accounts) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    const skillTokenAddress = '0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab';

    await deployProxy(SkillStakingRewardsUpgradeable, [accounts[0], accounts[0], skillTokenAddress, skillTokenAddress, 7 * 24 * 60 * 60], { deployer });
  }
};
