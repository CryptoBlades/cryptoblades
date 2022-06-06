const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require('SimpleQuests');

module.exports = async function (deployer) {
  const simpleQuests = await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
};
