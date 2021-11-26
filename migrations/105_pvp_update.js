const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const PvpArena = artifacts.require("PvpArena");

module.exports = async function (deployer) {
  const pvpArena = await PvpArena.deployed();
  await upgradeProxy(pvpArena.address, PvpArena, { deployer });
};