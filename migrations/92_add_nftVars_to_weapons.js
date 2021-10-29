const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');


const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer) {
  const weps = await Weapons.deployed();
  const _weps = await upgradeProxy(weps.address, Weapons, { deployer });
  _weps.migrateTo_NftVars();
};