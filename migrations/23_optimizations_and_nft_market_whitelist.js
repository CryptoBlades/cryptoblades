const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTMarket = artifacts.require("NFTMarket");
const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, _network, accounts) {
  const game = await CryptoBlades.deployed();
  await upgradeProxy(game.address, CryptoBlades, { deployer });

  const weps = await Weapons.deployed();
  await upgradeProxy(weps.address, Weapons, { deployer });

  const market = await NFTMarket.deployed();
  const newMarket = await upgradeProxy(market.address, NFTMarket, { deployer });

  const GAME_ADMIN = await newMarket.GAME_ADMIN();
  await newMarket.grantRole(GAME_ADMIN, accounts[0]);

  await Promise.all([
    newMarket.allowToken(Characters.address),
    newMarket.allowToken(Weapons.address)
  ]);
};
