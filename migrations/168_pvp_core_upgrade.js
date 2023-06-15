const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PvpCore = artifacts.require("PvpCore");

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
  || network === 'skaletestnet' || network === 'coinextestnet' || network === 'metertestnet' || network === 'opsidetestnet') {
    await upgradeProxy(PvpCore.address, PvpCore, { deployer });
  }
};