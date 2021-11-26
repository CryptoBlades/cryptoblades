const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Shields = artifacts.require("Shields");

module.exports = async function (deployer) {
  const shields = await Shields.deployed();
  const _shields = await upgradeProxy(shields.address, Shields, { deployer });
  _shields.migrateTo_NftVars();
};