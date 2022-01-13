const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network, accounts) {
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });
  const weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
  const simpleQuests = await deployProxy(SimpleQuests, [characters.address, weapons.address], { deployer });
  await characters.grantRole(await characters.GAME_ADMIN(), simpleQuests.address);
  await weapons.grantRole(await weapons.GAME_ADMIN(), simpleQuests.address);
};
