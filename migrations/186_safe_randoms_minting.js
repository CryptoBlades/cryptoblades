const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SafeRandoms = artifacts.require('SafeRandoms');
const CryptoBlades = artifacts.require('CryptoBlades');
const Blacksmith = artifacts.require('Blacksmith');

module.exports = async function (deployer) {
  const safeRandoms = await SafeRandoms.deployed();
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, {deployer});
  await safeRandoms.grantRole(await safeRandoms.GAME_ADMIN(), game.address);
  await game.setSafeRandoms(safeRandoms.address);
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, {deployer});
  await safeRandoms.grantRole(await safeRandoms.GAME_ADMIN(), blacksmith.address);
  await blacksmith.setSafeRandoms(safeRandoms.address);
};
