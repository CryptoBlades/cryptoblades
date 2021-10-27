const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");
const SkillToken = artifacts.require("SkillToken");
const ExperimentToken = artifacts.require("ExperimentToken");

module.exports = async function (deployer, network, accounts) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork' || network === 'hecomainnet' || network === 'okexmainnet' || network === 'polygonmainnet') {
    const rewardDistributorAddress = '0xC2573A26297a0c952C92bb48Fdcb6929524F7F48';
    let skillTokenAddress, lpTokenAddress;
    if (network === 'bscmainnet' || network === 'bscmainnet-fork') {

      skillTokenAddress = '0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab';
      lpTokenAddress = '0xC19dfd34D3ba5816dF9CBDaa02D32A9F8dc6F6fC';
    }
    else if(network === 'hecomainnet' || network === 'okexmainnet' || network === 'polygonmainnet') {
      const skillToken = await SkillToken.deployed();
      skillTokenAddress = skillToken.address;
      const lpToken = await ExperimentToken.deployed();
      lpTokenAddress = lpToken.address;
    }
    else assert.fail('Should never happen - but just in case');

    await deployProxy(LP2StakingRewardsUpgradeable, [accounts[0], rewardDistributorAddress, skillTokenAddress, lpTokenAddress, 0], { deployer });
  }
};

