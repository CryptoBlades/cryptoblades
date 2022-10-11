const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const SkillStakingRewardsUpgradeable60 = artifacts.require("SkillStakingRewardsUpgradeable60");
const ValorStakingRewardsUpgradeable = artifacts.require("ValorStakingRewardsUpgradeable");
const LPStakingRewardsUpgradeableValor = artifacts.require("LPStakingRewardsUpgradeableValor");
const LP2StakingRewardsUpgradeableValor = artifacts.require("LP2StakingRewardsUpgradeableValor");
const ValorToken = artifacts.require("ValorToken");
const Treasury = artifacts.require("Treasury");
const Raid1 = artifacts.require("Raid1");

module.exports = async function (deployer, network) {
  await upgradeProxy(Treasury.address, Treasury, { deployer });
  await upgradeProxy(Raid1.address, Raid1, { deployer });

  if (network === 'bscmainnet' || network === 'bscmainnet-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork') {
    const valorToken = await ValorToken.deployed();
    let ownerAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
    let rewardDistributorAddress;
    let kingTokenAddress;
    let skillTokenAddress;
    let lpSkillValor;
    let lpKingValor;
    const valorTokenAddress = valorToken.address;

    if(network === 'bscmainnet' || network === 'bscmainnet-fork') {
      rewardDistributorAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      kingTokenAddress = '0x0ccd575bf9378c06f6dca82f8122f570769f00c2';
      skillTokenAddress = '0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab';
      lpSkillValor = '0x8730c8deDc59E3BAFFb67bf1FA63d4F0E2D9ecC9'; // APESWAP SKILL/VALOR
      lpKingValor = '0xE487f184fB24D977D31Ff4347f9f6e0159ab537E'; // APESWAP KING/VALOR
    } 
    else if(network === 'bsctestnet' || network === 'bsctestnet-fork') {
      rewardDistributorAddress = '0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A';
      kingTokenAddress = '0x61F5197b43493a332A0E7D55B7ACa7c277e0BC4b'; //ExperimentToken address
      skillTokenAddress = '0xcAF53066e36EeF55eD0663419ADfF6E503bd134F';
      lpSkillValor = '0x61F5197b43493a332A0E7D55B7ACa7c277e0BC4b'; //ExperimentToken address
      lpKingValor = '0x61F5197b43493a332A0E7D55B7ACa7c277e0BC4b'; //ExperimentToken address
    }

    await deployProxy(SkillStakingRewardsUpgradeable60, [ownerAddress, ownerAddress, skillTokenAddress, skillTokenAddress, 60 * 60 * 24 * 60], { deployer });
    await deployProxy(ValorStakingRewardsUpgradeable, [ownerAddress, ownerAddress, valorTokenAddress, valorTokenAddress, 60 * 60 * 24 * 30], { deployer });
    await deployProxy(LPStakingRewardsUpgradeableValor, [ownerAddress, ownerAddress, valorTokenAddress, lpSkillValor, 60 * 60 * 24 * 30], { deployer });
    await deployProxy(LP2StakingRewardsUpgradeableValor, [ownerAddress, ownerAddress, valorTokenAddress, lpKingValor, 60 * 60 * 24 * 30], { deployer });
  }
};