const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PvpArena = artifacts.require("PvpArena");
const PvpRankings = artifacts.require("PvpRankings");

module.exports = async function (deployer, network, accounts) {
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
  || network === 'skaletestnet') {
    await upgradeProxy(PvpArena.address, PvpArena, { deployer });
    await upgradeProxy(PvpRankings.address, PvpRankings, { deployer });
  }
};