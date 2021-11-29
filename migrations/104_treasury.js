const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Treasury = artifacts.require("Treasury");
const CryptoBlades = artifacts.require("CryptoBlades");
const Merchandise = artifacts.require("Merchandise");

module.exports = async function (deployer, network, accounts) {
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(Merchandise.address, Merchandise, { deployer });
  const GAME_ADMIN = await game.GAME_ADMIN();

  const treasury = await deployProxy(Treasury, [game.address], { deployer });
  await game.grantRole(GAME_ADMIN, treasury.address);
};