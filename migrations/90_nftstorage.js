const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const NFTStorage = artifacts.require("NFTStorage");
const Shields = artifacts.require("Shields");
const Weapons = artifacts.require("Weapons");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer, network, accounts) {

  //const shields = await Shields.deployed();
  const weapons = await Weapons.deployed();
  const characters = await upgradeProxy(Characters.address, Characters, { deployer });
  
  const nftStorage = await deployProxy(NFTStorage, [weapons.address, characters.address], { deployer });
  
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });

  await blacksmith.migrateTo_a69635( nftStorage.address );
  

  
  //await nftStorage.allowToken(shields.address);
  await nftStorage.allowToken(weapons.address);
  await nftStorage.allowToken(characters.address);
  
  const weapons_MINTER_ROLE = await weapons.MINTER_ROLE();
  await weapons.grantRole(weapons_MINTER_ROLE, nftStorage.address);
  
  const characters_MINTER_ROLE = await characters.MINTER_ROLE();
  await characters.grantRole(characters_MINTER_ROLE, nftStorage.address);
  
  const characters_NO_OWNED_LIMIT = await characters.NO_OWNED_LIMIT();
  await characters.grantRole(characters_NO_OWNED_LIMIT, nftStorage.address);
};