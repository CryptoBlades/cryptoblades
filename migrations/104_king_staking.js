const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const KingStakingRewardsUpgradeable = artifacts.require('KingStakingRewardsUpgradeable');

module.exports = async function (deployer, network) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    const ownerAddress = '0xC2573A26297a0c952C92bb48Fdcb6929524F7F48';
    const rewardDistributorAddress = '0xC2573A26297a0c952C92bb48Fdcb6929524F7F48';
    const kingTokenAddress = '0x0ccd575bf9378c06f6dca82f8122f570769f00c2';

    await deployProxy(KingStakingRewardsUpgradeable, [ownerAddress, rewardDistributorAddress, kingTokenAddress, kingTokenAddress, 7 * 24 * 60 * 60], { deployer });
  }
};
