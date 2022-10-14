const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const ChainlinkRandoms = artifacts.require("ChainlinkRandoms");

module.exports = async function (deployer) {
  const nftStorage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
  const randoms = await ChainlinkRandoms.deployed();
  await nftStorage.migrateRandoms(randoms);
};