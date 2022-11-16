const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const PartnerVault = artifacts.require("PartnerVault");
const SimpleQuests = artifacts.require("SimpleQuests");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");

module.exports = async function (deployer) {
  await upgradeProxy(PartnerVault.address, PartnerVault, {deployer});
  await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
  await upgradeProxy(SkillStakingRewardsUpgradeable.address, SkillStakingRewardsUpgradeable, {deployer});
};
