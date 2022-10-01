const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const SkillStakingRewardsUpgradeable60 = artifacts.require("SkillStakingRewardsUpgradeable60");
const ValorStakingRewardsUpgradeable = artifacts.require("ValorStakingRewardsUpgradeable");
const LPStakingRewardsUpgradeableValor = artifacts.require("LPStakingRewardsUpgradeableValor");
const LP2StakingRewardsUpgradeableValor = artifacts.require("LP2StakingRewardsUpgradeableValor");
const ValorToken = artifacts.require("ValorToken");

module.exports = async function (deployer) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork') {
    const valorToken = await ValorToken.deployed();
    let ownerAddress;
    let rewardDistributorAddress;
    let kingTokenAddress;
    let skillTokenAddress;
    let lpTokenAddress;
    let lp2TokenAddress;
    const valorTokenAddress = valorToken.address;

    if(network === 'bscmainnet' || network === 'bscmainnet-fork') {
      await upgradeProxy(KingStakingRewardsUpgradeable.address, KingStakingRewardsUpgradeable, { deployer });

      ownerAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      rewardDistributorAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      kingTokenAddress = '0x0ccd575bf9378c06f6dca82f8122f570769f00c2';
      skillTokenAddress = '0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab';
      lpTokenAddress = '0x0dEB588c1EC6f1D9f348126D401f05c4c7B7a80c'; // APESWAP PAIR
      lp2TokenAddress = '0x60c4929133fbf067308be2010cbed2bb941bcdf7'; // BUSD/KING

    } 
    else if(network === 'bsctestnet' || network === 'bsctestnet-fork') {
      ownerAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      rewardDistributorAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      kingTokenAddress = '0x61F5197b43493a332A0E7D55B7ACa7c277e0BC4b'; //ExperimentToken address
      skillTokenAddress = '0xcAF53066e36EeF55eD0663419ADfF6E503bd134F';
      lpTokenAddress = '0x61F5197b43493a332A0E7D55B7ACa7c277e0BC4b'; //ExperimentToken address
      lp2TokenAddress = '0x61F5197b43493a332A0E7D55B7ACa7c277e0BC4b'; //ExperimentToken address
    }

    await deployProxy(SkillStakingRewardsUpgradeable60, [accounts[0], accounts[0], skillTokenAddress, skillTokenAddress, 60 * 60 * 24 * 60], { deployer });
    await deployProxy(ValorStakingRewardsUpgradeable, [accounts[0], accounts[0], valorTokenAddress, valorTokenAddress, 60 * 60 * 24 * 30], { deployer });
    await deployProxy(LPStakingRewardsUpgradeableValor, [accounts[0], accounts[0], valorTokenAddress, lpTokenAddress, 60 * 60 * 24 * 30], { deployer });
    await deployProxy(LP2StakingRewardsUpgradeableValor, [accounts[0], accounts[0], valorTokenAddress, lp2TokenAddress, 60 * 60 * 24 * 30], { deployer });
  }
};