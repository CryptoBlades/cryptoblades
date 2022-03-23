const { upgradeProxy, deployProxy } = require('@openzeppelin/truffle-upgrades');

const PartnerGiveaways = artifacts.require('PartnerGiveaways');
const SpecialWeaponsManager = artifacts.require('SpecialWeaponsManager');
const PvpArena = artifacts.require('PvpArena');

module.exports = async function (deployer, network) {
  const specialWeaponsManager = await SpecialWeaponsManager.deployed();
  const GAME_ADMIN = await specialWeaponsManager.GAME_ADMIN();
  const partnerGiveaways = await deployProxy(PartnerGiveaways, [specialWeaponsManager.address], { deployer });
  await specialWeaponsManager.grantRole(GAME_ADMIN, partnerGiveaways.address);
  await upgradeProxy(PvpArena.address, PvpArena, { deployer });
};
