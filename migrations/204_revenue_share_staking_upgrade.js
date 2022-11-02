const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const SkillStakingRewardsUpgradeable60 = artifacts.require("SkillStakingRewardsUpgradeable60");

module.exports = async function (deployer, network, accounts) {
    if(network === 'bscmainnet' || network === 'bscmainnet-fork') {
        await upgradeProxy(SkillStakingRewardsUpgradeable60.address, SkillStakingRewardsUpgradeable60, { deployer });
    }
};