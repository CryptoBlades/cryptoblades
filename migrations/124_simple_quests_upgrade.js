const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(Characters.address, Characters, {deployer});
  await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
};
