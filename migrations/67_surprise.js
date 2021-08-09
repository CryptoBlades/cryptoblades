const { upgradeProxy, deployProxy } = require('@openzeppelin/truffle-upgrades');

const Weapons = artifacts.require('Weapons');
const Promos = artifacts.require('Promos');
const Shields = artifacts.require("Shields");
const NFTMarket = artifacts.require("NFTMarket");
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {
  const promos = await upgradeProxy(Promos.address, Promos, { deployer });
  const market = await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  const GAME_ADMIN = await promos.GAME_ADMIN();
  await promos.grantRole(GAME_ADMIN, accounts[0]);
  const weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
  const shields = await upgradeProxy(Shields.address, Shields, { deployer });
  await weapons.migrateTo_surprise(promos.address);
  await shields.migrateTo_surprise(promos.address);
};
