const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CBKLandT1StakingRewardsUpgradeable = artifacts.require('CBKLandT1StakingRewardsUpgradeable');
const CBKLandT2StakingRewardsUpgradeable = artifacts.require('CBKLandT2StakingRewardsUpgradeable');
const CBKLandT3StakingRewardsUpgradeable = artifacts.require('CBKLandT3StakingRewardsUpgradeable');

module.exports = async function (deployer, network) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork') {
    await upgradeProxy(CBKLandT1StakingRewardsUpgradeable.address, CBKLandT1StakingRewardsUpgradeable, { deployer });
    await upgradeProxy(CBKLandT2StakingRewardsUpgradeable.address, CBKLandT2StakingRewardsUpgradeable, { deployer });
    await upgradeProxy(CBKLandT3StakingRewardsUpgradeable.address, CBKLandT3StakingRewardsUpgradeable, { deployer });
  }
};
