const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");

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
    || network === 'skaletestnet') {
        await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
        await upgradeProxy(Characters.address, Characters, { deployer });
        await upgradeProxy(Weapons.address, Weapons, { deployer });
    }
};