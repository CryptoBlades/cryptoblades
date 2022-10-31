const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");
const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");

module.exports = async function (deployer, network, accounts) {
    if(network === 'bscmainnet' || network === 'bscmainnet-fork') {
        await upgradeProxy(LPStakingRewardsUpgradeable.address, LPStakingRewardsUpgradeable, { deployer });
        await upgradeProxy(LP2StakingRewardsUpgradeable.address, LP2StakingRewardsUpgradeable, { deployer });
    }
};