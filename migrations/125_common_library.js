const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PvpArena = artifacts.require("PvpArena");
const CryptoBlades = artifacts.require("CryptoBlades");
const Raid1 = artifacts.require("Raid1");

module.exports = async function (deployer, network) {

    const pvp = await upgradeProxy(PvpArena.address, PvpArena, { deployer });
    let pvpGasOffset = web3.utils.toWei('0.005', 'ether'); // default

    if(network === 'bscmainnet') {
        pvpGasOffset = web3.utils.toWei('0.005', 'ether');
    }
    else if(network === 'hecomainnet') {
        pvpGasOffset = web3.utils.toWei('0.001', 'ether');
    }
    else if(network === 'okexmainnet') {
        pvpGasOffset = web3.utils.toWei('0.0001', 'ether');
    }
    else if(network === 'polygonmainnet') {
        pvpGasOffset = web3.utils.toWei('0.035', 'ether');
    }
    else if(network === 'avaxmainnet') {
        pvpGasOffset = web3.utils.toWei('0.03', 'ether');
    }
    await pvp.setDuelOffsetCost(pvpGasOffset);
    await pvp.setPvpBotAddress("0xC24658012D08a8A575Aa140C7EE45e83c9100F73");

    await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    await upgradeProxy(Raid1.address, Raid1, { deployer });
};