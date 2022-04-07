const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SpecialWeaponsManager = artifacts.require('SpecialWeaponsManager');

module.exports = async function (deployer) {
  await upgradeProxy(SpecialWeaponsManager.address, SpecialWeaponsManager, {deployer});
};
