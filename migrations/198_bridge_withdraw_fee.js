const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");

module.exports = async function (deployer) {
  await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
};