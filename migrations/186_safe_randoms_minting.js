const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SafeRandoms = artifacts.require('SafeRandoms');
const CryptoBlades = artifacts.require('CryptoBlades');
const Blacksmith = artifacts.require('Blacksmith');

module.exports = async function (deployer) {
  const safeRandoms = await SafeRandoms.deployed();
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, {deployer});
  await safeRandoms.grantRole(await safeRandoms.GAME_ADMIN(), game.address);
  const LINK_SAFE_RANDOMS_GAME = await game.LINK_SAFE_RANDOMS();
  await game.setLink(LINK_SAFE_RANDOMS_GAME, safeRandoms.address);
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, {deployer});
  await safeRandoms.grantRole(await safeRandoms.GAME_ADMIN(), blacksmith.address);
  const LINK_SAFE_RANDOMS_BLACKSMITH = await blacksmith.LINK_SAFE_RANDOMS();
  await blacksmith.setLink(LINK_SAFE_RANDOMS_BLACKSMITH, safeRandoms.address);
};
