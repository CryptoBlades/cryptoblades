const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const Dex = artifacts.require("Dex");

module.exports = async function (deployer) {
  await upgradeProxy(Dex.address, Dex, {deployer});
};
