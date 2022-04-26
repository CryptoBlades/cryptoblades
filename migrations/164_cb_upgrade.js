const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const CryptoBlades = artifacts.require("CryptoBlades");

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
        await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    }
};