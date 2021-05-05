const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");

module.exports = async function (deployer, network) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    const ownerAddress = '0xC2573A26297a0c952C92bb48Fdcb6929524F7F48';
    const rewardDistributorAddress = '0xC2573A26297a0c952C92bb48Fdcb6929524F7F48';

    const skillTokenAddress = '0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab';
    const lpTokenAddress = '0xc19dfd34d3ba5816df9cbdaa02d32a9f8dc6f6fc';

    await deployProxy(LP2StakingRewardsUpgradeable, [ownerAddress, rewardDistributorAddress, skillTokenAddress, lpTokenAddress, 0], { deployer });
  }
};

