const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const KingStakingRewardsUpgradeable90 = artifacts.require('KingStakingRewardsUpgradeable90');
const KingStakingRewardsUpgradeable180 = artifacts.require('KingStakingRewardsUpgradeable180');
const SkillStakingRewardsUpgradeable90 = artifacts.require('SkillStakingRewardsUpgradeable90');
const SkillStakingRewardsUpgradeable180 = artifacts.require('SkillStakingRewardsUpgradeable180');
const CBKLandT1StakingRewardsUpgradeable = artifacts.require('CBKLandT1StakingRewardsUpgradeable');
const CBKLandT2StakingRewardsUpgradeable = artifacts.require('CBKLandT2StakingRewardsUpgradeable');
const CBKLandT3StakingRewardsUpgradeable = artifacts.require('CBKLandT3StakingRewardsUpgradeable');
const CBKLand = artifacts.require('CBKLand');

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CBKLand.address, CBKLand, { deployer });

  if (network === 'bscmainnet' || network === 'bscmainnet-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork') {
    let ownerAddress;
    let rewardDistributorAddress;
    let kingTokenAddress;
    let skillTokenAddress;
    let cbkLandTokenAddress;

    if(network === 'bscmainnet' || network === 'bscmainnet-fork') {
      ownerAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      rewardDistributorAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      kingTokenAddress = '0x0ccd575bf9378c06f6dca82f8122f570769f00c2';
      skillTokenAddress = '0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab';
      cbkLandTokenAddress = '0xd3b5df75a4d0d87Add79A5bdAB2f865928F7Fc8e';
    } 
    else if(network === 'bsctestnet' || network === 'bsctestnet-fork') {
      ownerAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      rewardDistributorAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      kingTokenAddress = '0x61F5197b43493a332A0E7D55B7ACa7c277e0BC4b'; //ExperimentToken address
      skillTokenAddress = '0xcAF53066e36EeF55eD0663419ADfF6E503bd134F';
      cbkLandTokenAddress = '0xE986e14afe3744a986F1A4Bcaa174C84ae1C4B91';
    }

    // ERC20
    const KingStaking90 = await deployProxy(KingStakingRewardsUpgradeable90, [ownerAddress, rewardDistributorAddress, kingTokenAddress, kingTokenAddress, 7 * 24 * 60 * 60], { deployer });
    const KingStaking180 = await deployProxy(KingStakingRewardsUpgradeable180, [ownerAddress, rewardDistributorAddress, kingTokenAddress, kingTokenAddress, 7 * 24 * 60 * 60], { deployer });
  
    await KingStaking90.setRewardsDuration('7776000');
    await KingStaking180.setRewardsDuration('15552000');

    const SkillStaking90 = await deployProxy(SkillStakingRewardsUpgradeable90, [ownerAddress, rewardDistributorAddress, skillTokenAddress, skillTokenAddress, 7 * 24 * 60 * 60], { deployer });
    const SkillStaking180 = await deployProxy(SkillStakingRewardsUpgradeable180, [ownerAddress, rewardDistributorAddress, skillTokenAddress, skillTokenAddress, 7 * 24 * 60 * 60], { deployer });
  
    await SkillStaking90.setRewardsDuration('7776000');
    await SkillStaking180.setRewardsDuration('15552000');

    // ERC721
    const CBKLandT1Staking = await deployProxy(CBKLandT1StakingRewardsUpgradeable, [ownerAddress, rewardDistributorAddress, kingTokenAddress, cbkLandTokenAddress, 7 * 24 * 60 * 60, cbkLandTokenAddress], { deployer });
    await CBKLandT1Staking.setRewardsDuration('2592000')
    const CBKLandT2Staking = await deployProxy(CBKLandT2StakingRewardsUpgradeable, [ownerAddress, rewardDistributorAddress, kingTokenAddress, cbkLandTokenAddress, 7 * 24 * 60 * 60, cbkLandTokenAddress], { deployer });
    await CBKLandT2Staking.setRewardsDuration('7776000')
    const CBKLandT3Staking = await deployProxy(CBKLandT3StakingRewardsUpgradeable, [ownerAddress, rewardDistributorAddress, kingTokenAddress, cbkLandTokenAddress, 7 * 24 * 60 * 60, cbkLandTokenAddress], { deployer });
    await CBKLandT3Staking.setRewardsDuration('15552000')
  }
};
