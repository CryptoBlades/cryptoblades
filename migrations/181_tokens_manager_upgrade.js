const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const CryptoBlades = artifacts.require("CryptoBlades");
const TokensManager = artifacts.require("TokensManager");

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
    || network === 'skaletestnet' || network === 'coinextestnet') {
        await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
        await upgradeProxy(TokensManager.address, TokensManager, { deployer });
    }
};