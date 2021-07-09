const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer) {
  const promos = await deployProxy(Promos, [], { deployer });

  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  const charas = await upgradeProxy(Characters.address, Characters, { deployer });
  await game.migrateTo_ef994e2(promos.address);
  await charas.migrateTo_ef994e2(promos.address);

  const promos_GAME_ADMIN = await promos.GAME_ADMIN();
  await promos.grantRole(promos_GAME_ADMIN, charas.address);
};
