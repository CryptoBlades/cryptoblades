const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const PvpArena = artifacts.require("PvpArena");

module.exports = async function (deployer, network) {
    if (network === "development"
    || network === "development-fork"
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet'
    || network === 'avaxtestnet'
    || network === 'avaxtestnet-fork') {
        await upgradeProxy(PvpArena.address, PvpArena, { deployer });
    }


};