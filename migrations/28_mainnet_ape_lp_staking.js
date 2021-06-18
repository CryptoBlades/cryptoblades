const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");

module.exports = async function (deployer, network, accounts) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    const rewardDistributorAddress = '0xC2573A26297a0c952C92bb48Fdcb6929524F7F48';

    const skillTokenAddress = '0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab';
    const lpTokenAddress = '0x0dEB588c1EC6f1D9f348126D401f05c4c7B7a80c';

    await deployProxy(LPStakingRewardsUpgradeable, [accounts[0], rewardDistributorAddress, skillTokenAddress, lpTokenAddress, 0], { deployer });
  }
};

