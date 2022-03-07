const {upgradeProxy} = require("@openzeppelin/truffle-upgrades");

const SimpleQuests = artifacts.require("SimpleQuests");

module.exports = async function (deployer) {
  await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
};
