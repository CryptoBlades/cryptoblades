const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer) {
  const charas = await Characters.deployed();
  const newCharas = await upgradeProxy(charas.address, Characters, { deployer });
  await newCharas.migrateTo_951a020();

  const weps = await Weapons.deployed();
  const newWeps = await upgradeProxy(weps.address, Weapons, { deployer });
  await newWeps.migrateTo_951a020();
};
