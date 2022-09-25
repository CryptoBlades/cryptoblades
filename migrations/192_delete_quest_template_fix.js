const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");

module.exports = async function (deployer, network) {
  await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
};
