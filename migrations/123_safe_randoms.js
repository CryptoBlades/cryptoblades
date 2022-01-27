const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SafeRandoms = artifacts.require("SafeRandoms");
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {
  const safeRandoms = await deployProxy(SafeRandoms, [], { deployer });
  const GAME_ADMIN = await safeRandoms.GAME_ADMIN();
  await safeRandoms.grantRole(GAME_ADMIN, accounts[0]);

  // test stuff
  /*const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await game.setSafeRandom(safeRandoms.address);
  await safeRandoms.grantRole(GAME_ADMIN, game.address);*/
};
