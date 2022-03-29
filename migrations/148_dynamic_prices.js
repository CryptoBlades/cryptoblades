const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require('CryptoBlades');
const Blacksmith = artifacts.require("Blacksmith");

module.exports = async function (deployer, network) {
  if (network === "development"
    || network === "development-fork"
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet'
    || network === 'avaxtestnet'
    || network === 'avaxtestnet-fork'
    || network === 'auroratestnet') {
    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });

    await game.setVars([19, 20, 21, 22, 23], ['100000000000000', '10000000000000000', '100000000000000000', '100', '1000']);
  }
};
