const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SafeRandoms = artifacts.require("SafeRandoms");

module.exports = async function (deployer, network) {
  await upgradeProxy(SafeRandoms.address, SafeRandoms, { deployer });
};
