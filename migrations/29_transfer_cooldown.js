const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const NFTMarket = artifacts.require("NFTMarket");

module.exports = async function (deployer) {
  const charas = await Characters.deployed();
  const newCharas = await upgradeProxy(charas.address, Characters, { deployer });
  await newCharas.migrateTo_951a020();

  const weps = await Weapons.deployed();
  const newWeps = await upgradeProxy(weps.address, Weapons, { deployer });
  await newWeps.migrateTo_951a020();

  const RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP = await newWeps.RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP();

  await Promise.all([
    newWeps.grantRole(RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP, NFTMarket.address),
    newCharas.grantRole(RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP, NFTMarket.address),
  ]);
};
