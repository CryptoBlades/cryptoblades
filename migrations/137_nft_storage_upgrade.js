const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const NFTStorage = artifacts.require("NFTStorage");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network) {
  await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
  await upgradeProxy(Weapons.address, Weapons, { deployer });
};