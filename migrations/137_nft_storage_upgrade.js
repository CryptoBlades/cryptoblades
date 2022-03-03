const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const NFTStorage = artifacts.require("NFTStorage");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network) {
  if (network === "development"
  || network === "development-fork"
  || network === 'bsctestnet'
  || network === 'bsctestnet-fork'
  || network === 'hecotestnet'
  || network === 'okextestnet'
  || network === 'polygontestnet'
  || network === 'avaxtestnet'
  || network === 'avaxtestnet-fork'
  || network === 'auroratestnet') {
    await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
    await upgradeProxy(Weapons.address, Weapons, { deployer });
  }
};