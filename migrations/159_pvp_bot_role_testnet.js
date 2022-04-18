const PvpCore = artifacts.require("PvpCore");
const PvpRankings = artifacts.require("PvpRankings");

module.exports = async function (deployer, network, accounts) {
    if (network === 'bsctestnet' || network === 'bsctestnet-fork') {
        const pvpBotAddress = '0xC24658012D08a8A575Aa140C7EE45e83c9100F73'

        const pvpRankings = await PvpRankings.deployed()

        const pvpCore = await PvpCore.deployed()

        await pvpCore.grantRole(await pvpCore.GAME_ADMIN(), pvpBotAddress);
        await pvpRankings.grantRole(await pvpRankings.GAME_ADMIN(), pvpBotAddress);

        await pvpCore.setPvpBotAddress(pvpBotAddress);
    }
};