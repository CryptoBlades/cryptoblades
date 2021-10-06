const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const NFTStorage = artifacts.require("NFTStorage");
const Shields = artifacts.require("Shields");
const Weapons = artifacts.require("Weapons");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer, network, accounts) {

  const nftStorage = await deployProxy(NFTStorage, { deployer });
  
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });

  await blacksmith.migrateTo_a69635( nftStorage.address );
  
  const shields = await Shields.deployed();
  const weapons = await Weapons.deployed();
  const characters = await Characters.deployed();
  
  await nftStorage.allowToken(shields.address);
  await nftStorage.allowToken(weapons.address);
  await nftStorage.allowToken(characters.address);
};