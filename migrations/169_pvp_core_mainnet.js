const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PvpCore = artifacts.require("PvpCore");
const PvpRankings = artifacts.require("PvpRankings");

module.exports = async function (deployer, network, accounts) {
  if (network === 'bscmainnet'
    || network === 'bscmainnet-fork'
    || network === 'hecomainnet'
    || network === 'okexmainnet'
    || network === 'polygonmainnet'
    || network === 'avaxmainnet'
    || network === 'avaxmainnet-fork'
    || network === 'auroramainnet'
    || network === 'skalemainnet' || network === 'coinexmainnet' || network === 'metermainnet'  || network === 'cronosmainnet'
    || network === 'kavamainnet') {
    await upgradeProxy(PvpCore.address, PvpCore, { deployer });
    const pvpRankings = await PvpRankings.deployed();
    await pvpRankings.setSeasonDuration(86400);
  }
};