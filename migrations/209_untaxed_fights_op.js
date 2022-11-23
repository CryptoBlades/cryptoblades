const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network) {
    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    if(network === 'bscmainnet'
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork') {
        const VAR_FIGHT_UNTAXED = await game.VAR_FIGHT_UNTAXED();
        await game.setVar(VAR_FIGHT_UNTAXED, 1);
    }
};