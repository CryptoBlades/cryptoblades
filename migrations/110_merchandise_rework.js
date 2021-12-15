const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const Merchandise = artifacts.require("Merchandise");

module.exports = async function (deployer) {
  await upgradeProxy(Merchandise.address, Merchandise, {deployer});
};
