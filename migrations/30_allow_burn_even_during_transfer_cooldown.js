const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer) {
  const charas = await Characters.deployed();
  await upgradeProxy(charas.address, Characters, { deployer });

  const weps = await Weapons.deployed();
  await upgradeProxy(weps.address, Weapons, { deployer });
};
