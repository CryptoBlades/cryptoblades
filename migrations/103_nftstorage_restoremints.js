const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Weapons = artifacts.require("Weapons");
const Characters = artifacts.require("Characters");
const NFTStorage = artifacts.require("NFTStorage");
const Promos = artifacts.require("Promos");
const Blacksmith = artifacts.require("Blacksmith");

module.exports = async function (deployer, network, accounts) {
   const promos = await Promos.deployed();
   const storage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
   await storage.migrateTo_98bf302(promos.address);
   
   await upgradeProxy(Characters.address, Characters, { deployer });
   await upgradeProxy(Weapons.address, Weapons, { deployer });
   await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
};
