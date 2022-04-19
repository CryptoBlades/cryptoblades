const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const PvpCore = artifacts.require("PvpCore");
const PvpRankings = artifacts.require("PvpRankings");

module.exports = async function (deployer, network, accounts) {
    if (
      network === "development" ||
      network === "development-fork" ||
      network === 'bsctestnet' ||
      network === 'bsctestnet-fork' ||
      network === 'hecotestnet' ||
      network === 'okextestnet' ||
      network === 'polygontestnet' ||
      network === 'avaxtestnet' ||
      network === 'avaxtestnet-fork' ||
      network === 'auroratestnet'
  ) {    
    const pvpCore = await upgradeProxy(PvpCore.address, PvpCore, { deployer });

    if (network === 'bsctestnet' || network === 'bsctestnet-fork') {
      const pvpBotAddress = '0xC24658012D08a8A575Aa140C7EE45e83c9100F73';

      const pvpRankings = await PvpRankings.deployed();

      await pvpCore.grantRole(await pvpCore.GAME_ADMIN(), pvpBotAddress);
      await pvpRankings.grantRole(await pvpRankings.GAME_ADMIN(), pvpBotAddress);

      await pvpCore.setPvpBotAddress(pvpBotAddress);
    }
  }
};