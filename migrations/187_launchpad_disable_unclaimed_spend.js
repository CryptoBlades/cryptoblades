const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const Launchpad = artifacts.require("Launchpad");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(Launchpad.address, Launchpad, {deployer});
};
