const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");

module.exports = async function (deployer) {
  const nftStorage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
  await nftStorage.setWithdrawFromStorageNativeFee(Characters.address, '3000000000000000');
  await nftStorage.setWithdrawFromStorageNativeFee(Weapons.address, '3000000000000000');
  await nftStorage.setWithdrawFromStorageNativeFee(Shields.address, '3000000000000000');
};