const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");

module.exports = async function (deployer, network, accounts) {
	
  const SimpleQuests = await deployProxy(SimpleQuests, [], { deployer });

};