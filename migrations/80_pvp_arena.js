const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const PvpArena = artifacts.require("PvpArena");

module.exports = function(deployer) {
  const game = await CryptoBlades.deployed();
  const characters = await Characters.deployed();
  const weapons = await Weapons.deployed();
  
  const pvpArena = await deployProxy(PvpArena, [game.address], { deployer });

  const GAME_ADMIN = await pvpArena.GAME_ADMIN();

  await game.grantRole(GAME_ADMIN, pvpArena.address);
  await characters.grantRole(GAME_ADMIN, pvpArena.address);
  await weapons.grantRole(GAME_ADMIN, pvpArena.address);
};
