const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Treasury = artifacts.require("Treasury");
const CryptoBlades = artifacts.require("CryptoBlades");


module.exports = async function (deployer, network, accounts) {
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  const GAME_ADMIN = await game.GAME_ADMIN();

  const treasury = await deployProxy(Treasury, [game.address], { deployer });
  game.grantRole(GAME_ADMIN, treasury.address);
};