const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer, network, accounts) {
	
  const SimpleQuests = await deployProxy(SimpleQuests, [], { deployer });
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });

};