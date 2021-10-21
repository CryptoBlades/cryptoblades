const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const { artifacts } = require("hardhat");

const Characters = artifacts.require("Characters");


module.exports = async function (deployer) {
  const charas = await Characters.deployed();
  const _charas = await upgradeProxy(charas.address, Characters, { deployer });
  _charas.migrateTo_NftVars();
};
