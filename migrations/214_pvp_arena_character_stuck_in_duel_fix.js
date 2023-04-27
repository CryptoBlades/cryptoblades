const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const PvpCore = artifacts.require("PvpCore");

module.exports = async function (deployer) {
  await upgradeProxy(PvpCore.address, PvpCore, {deployer});
};
