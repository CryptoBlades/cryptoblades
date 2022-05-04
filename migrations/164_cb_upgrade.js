const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const CryptoBlades = artifacts.require("CryptoBlades");
const TokensManager = artifacts.require("TokensManager");

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

        const tokensManager = await TokensManager.deployed();

        await game.grantRole(await game.GAME_ADMIN(), tokensManager.address);
    }
};