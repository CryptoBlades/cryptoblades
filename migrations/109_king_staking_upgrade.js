const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const KingStakingRewardsUpgradeable = artifacts.require('KingStakingRewardsUpgradeable');

module.exports = async function (deployer, network, accounts) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    await upgradeProxy(KingStakingRewardsUpgradeable.address, KingStakingRewardsUpgradeable, { deployer });
  }
};
