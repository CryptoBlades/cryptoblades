const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");
const PartnerVault = artifacts.require("PartnerVault");

module.exports = async function (deployer, network) {
  await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
  const characters = await Characters.deployed();
  const partnerVault = await PartnerVault.deployed();
  const NO_OWNED_LIMIT = await characters.NO_OWNED_LIMIT();
  if (!(await characters.hasRole(NO_OWNED_LIMIT, partnerVault.address))) {
    await characters.grantRole(NO_OWNED_LIMIT, partnerVault.address);
  }
};
