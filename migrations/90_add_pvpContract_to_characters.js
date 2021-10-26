const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const { artifacts } = require("hardhat");

const Characters = artifacts.require("Characters");
const PvpArena = artifacts.require("PvpArena");

module.exports = async function (deployer) {
  const charas = await Characters.deployed();
  const pvpArena = await PvpArena.deployed();
  const _charas = await upgradeProxy(charas.address, Characters, { deployer });
  await _charas.migrateTo_PvpArena(pvpArena.address);
  await pvpArena.grantRole(pvpArena_GAME_ADMIN, _charas.address);
};
