const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const PvpArena = artifacts.require("PvpArena");
const Shields = artifacts.require("Shields");
const Raid1 = artifacts.require("Raid1");

module.exports = async function (deployer) {
  const game = await CryptoBlades.deployed();
  const shields = await Shields.deployed();
  const raids = await Raid1.deployed();

  const pvpArena = await deployProxy(
    PvpArena,
    [game.address, shields.address, raids.address],
    { deployer }
  );

  const GAME_ADMIN = await pvpArena.GAME_ADMIN();

  await game.grantRole(GAME_ADMIN, pvpArena.address);
};
