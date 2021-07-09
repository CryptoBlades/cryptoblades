const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer) {
  const game = await CryptoBlades.deployed();
  const charas = await Characters.deployed();
  const promos = await Promos.deployed();
  await game.migrateTo_x(promos.address);
  await charas.migrateTo_x(promos.address);
};
