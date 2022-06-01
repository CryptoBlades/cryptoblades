const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require('SimpleQuests');
const SafeRandoms = artifacts.require("SafeRandoms");

module.exports = async function (deployer, network) {
  await upgradeProxy(SimpleQuests.address, SimpleQuests, { deployer });
  await upgradeProxy(SafeRandoms.address, SafeRandoms, { deployer });
};
