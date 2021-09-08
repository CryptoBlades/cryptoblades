const SkillStakingRewards = artifacts.require("SkillStakingRewards");
const LPStakingRewards = artifacts.require("LPStakingRewards");

module.exports = async function (deployer, network) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    const ownerAddress = '0xC2573A26297a0c952C92bb48Fdcb6929524F7F48';
    const rewardDistributorAddress = '0xC2573A26297a0c952C92bb48Fdcb6929524F7F48';

    const skillTokenAddress = '0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab';
    const lpTokenAddress = '0xf0252108666A9a6B473aB4028781965064D78147';

    // 0.001 minimumStakeAmount
    await deployer.deploy(SkillStakingRewards, ownerAddress, rewardDistributorAddress, skillTokenAddress, skillTokenAddress, 1000000000000000, 7 * 24 * 60 * 60);

    // 0.001 minimumStakeAmount
    await deployer.deploy(LPStakingRewards, ownerAddress, rewardDistributorAddress, skillTokenAddress, lpTokenAddress, 1000000000000000, 0);
  }
};
