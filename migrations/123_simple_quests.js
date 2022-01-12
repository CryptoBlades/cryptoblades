const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer, network, accounts) {
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });
  const simpleQuests = await deployProxy(SimpleQuests, [characters.address], { deployer });
  await characters.grantRole(await characters.GAME_ADMIN(), simpleQuests.address);
};
