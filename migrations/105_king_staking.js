const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const KingStakingRewardsUpgradeable = artifacts.require('KingStakingRewardsUpgradeable');

module.exports = async function (deployer, network) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    const ownerAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
    const rewardDistributorAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
    const kingTokenAddress = '0x0ccd575bf9378c06f6dca82f8122f570769f00c2';

    await deployProxy(KingStakingRewardsUpgradeable, [ownerAddress, rewardDistributorAddress, kingTokenAddress, kingTokenAddress, 7 * 24 * 60 * 60], { deployer });
  }
};
