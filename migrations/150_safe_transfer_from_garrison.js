const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const Characters = artifacts.require('Characters');
const Garrison = artifacts.require('Garrison');

module.exports = async function (deployer) {
  await upgradeProxy(Garrison.address, Garrison, {deployer});
  await upgradeProxy(Characters.address, Characters, {deployer});
};
