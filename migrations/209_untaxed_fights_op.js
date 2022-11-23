const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const TokensManager = artifacts.require("TokensManager");

module.exports = async function (deployer, network) {
    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    await upgradeProxy(TokensManager.address, TokensManager, { deployer });
    if(network === 'bscmainnet'
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork') {
        const VAR_FIGHT_UNTAXED = await game.VAR_FIGHT_UNTAXED();
        await game.setVar(VAR_FIGHT_UNTAXED, 1);
    }
};