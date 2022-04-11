const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require('CryptoBlades');

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

    // VAR_MINT_WEAPON_FEE_DECREASE_SPEED = 19
    // VAR_MINT_CHARACTER_FEE_DECREASE_SPEED = 20
    // VAR_WEAPON_FEE_INCREASE = 21
    // VAR_CHARACTER_FEE_INCREASE = 22
    // VAR_MIN_WEAPON_FEE = 23
    // VAR_MIN_CHARACTER_FEE = 24
    await game.setVars([19, 20, 21, 22, 23, 24], ['100000000000000', '1000000000000000', '10000000000000000', '100000000000000000', '100', '1000']);
  }
};
