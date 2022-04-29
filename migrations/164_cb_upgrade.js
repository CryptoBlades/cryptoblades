const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const CryptoBlades = artifacts.require("CryptoBlades");
const TokensPrices = artifacts.require("TokensPrices");
const TokensReceiver = artifacts.require("TokensReceiver");

module.exports = async function (deployer, network) {
    if (network === "development"
    || network === "development-fork"
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet'
    || network === 'avaxtestnet'
    || network === 'avaxtestnet-fork' || network === 'auroratestnet') {
        const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

        const tokensPrices = await TokensPrices.deployed();
        const tokensReceiver = await TokensReceiver.deployed();

        await game.grantRole(await game.GAME_ADMIN(), tokensReceiver.address);
        await game.setTokensPricesAddress(tokensPrices.address);
    }
};