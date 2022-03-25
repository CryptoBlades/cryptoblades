const Junk = artifacts.require("Junk");
const KeyLootbox = artifacts.require("KeyLootbox");
const NFTMarket = artifacts.require("NFTMarket");
const RaidTrinket = artifacts.require('RaidTrinket');

module.exports = async function (deployer) {
  const junk = await Junk.deployed();
  const keyLootbox = await KeyLootbox.deployed();
  const trinket = await RaidTrinket.deployed();

  const market = await NFTMarket.deployed();
  await market.allowToken(junk.address);
  await market.allowToken(keyLootbox.address);
  await market.allowToken(trinket.address);
};
