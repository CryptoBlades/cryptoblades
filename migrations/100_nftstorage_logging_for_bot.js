const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTStorage = artifacts.require("NFTStorage");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
};
