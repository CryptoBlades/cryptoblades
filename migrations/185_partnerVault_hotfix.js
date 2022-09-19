const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const PartnerVault = artifacts.require("PartnerVault");

module.exports = async function (deployer, network, accounts) {
  const partnerVault = await upgradeProxy(PartnerVault.address, PartnerVault, {deployer});
};
