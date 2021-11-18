const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Weapons = artifacts.require("Weapons");
const Characters = artifacts.require("Characters");
const NFTStorage = artifacts.require("NFTStorage");

module.exports = async function (deployer, network, accounts) {
   await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
   await upgradeProxy(Characters.address, Characters, { deployer });
   await upgradeProxy(Weapons.address, Weapons, { deployer });
};
