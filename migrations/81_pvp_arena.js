const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const PvpArena = artifacts.require("PvpArena");
const Shields = artifacts.require("Shields");
const Raid1 = artifacts.require("Raid1");
const DummyRandoms = artifacts.require("DummyRandoms");
const ChainlinkRandoms = artifacts.require("ChainlinkRandoms");

module.exports = async function (deployer, network) {
  const game = await CryptoBlades.deployed();
  const shields = await Shields.deployed();
  const raids = await Raid1.deployed();

  let randoms;

  if (network === "development" || network === "development-fork") {
    randoms = await DummyRandoms.deployed();
  } else {
    randoms = await ChainlinkRandoms.deployed();
  }

  const pvpArena = await deployProxy(
    PvpArena,
    [game.address, shields.address, raids.address, randoms.address],
    { deployer }
  );

  await game.grantRole(await game.GAME_ADMIN(), pvpArena.address);
  await pvpArena.grantRole(await pvpArena.GAME_ADMIN(), deployer.networks[network].from);
};
