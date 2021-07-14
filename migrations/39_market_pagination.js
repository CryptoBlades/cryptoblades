const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTMarket = artifacts.require("NFTMarket");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer) {
  const market = await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });

  await market.migrateTo_a98a9ac(Characters.address, Weapons.address);
};
