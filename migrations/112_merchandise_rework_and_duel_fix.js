const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const Merchandise = artifacts.require("Merchandise");
const PvpArena = artifacts.require("PvpArena");

module.exports = async function (deployer) {
  await upgradeProxy(Merchandise.address, Merchandise, {deployer});
  await upgradeProxy(PvpArena.address, PvpArena, { deployer });
};
