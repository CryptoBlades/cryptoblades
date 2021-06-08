const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTMarket = artifacts.require("NFTMarket");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer) {
  const charas = await Characters.deployed();
  const newCharas = await upgradeProxy(charas.address, Characters, { deployer });

  const NO_OWNED_LIMIT = await newCharas.NO_OWNED_LIMIT();
  await newCharas.grantRole(NO_OWNED_LIMIT, NFTMarket.address);
};
