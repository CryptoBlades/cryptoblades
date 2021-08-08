const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SeedVault = artifacts.require("SeedVault");

module.exports = async function (deployer, network, accounts) {
  const seedVault = await deployProxy(SeedVault, [], { deployer });
  /*const game_GAME_ADMIN = await game.GAME_ADMIN();
  await game.grantRole(game_GAME_ADMIN, blacksmith.address);*/
};
