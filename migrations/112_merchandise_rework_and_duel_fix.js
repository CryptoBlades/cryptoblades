const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const Merchandise = artifacts.require("Merchandise");
const PvpArena = artifacts.require("PvpArena");

module.exports = async function (deployer, network) {
  await upgradeProxy(Merchandise.address, Merchandise, {deployer});
  
  if (network === "development"
  || network === "development-fork"
  || network === 'bsctestnet'
  || network === 'bsctestnet-fork'
  || network === 'hecotestnet'
  || network === 'okextestnet'
  || network === 'polygontestnet'
  || network === 'avaxtestnet'
  || network === 'avaxtestnet-fork'
  || network === 'auroratestnet'
  || network === 'kavatestnet'
  || network === 'skaletestnet' || network === 'coinextestnet') {
    await upgradeProxy(PvpArena.address, PvpArena, { deployer });
  }
};
