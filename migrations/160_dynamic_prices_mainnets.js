const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require('CryptoBlades');

module.exports = async function (deployer, network) {
  if (network === 'bscmainnet'
    || network === 'bscmainnet-fork'
    || network === 'hecomainnet'
    || network === 'okexmainnet'
    || network === 'polygonmainnet'
    || network === 'avaxmainnet'
    || network === 'avaxmainnet-fork'
    || network === 'auroramainnet'
    || network === 'skalemainnet'
    || network === 'kavamainnet') {
    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

    // VAR_MINT_WEAPON_FEE_DECREASE_SPEED = 19
    // VAR_MINT_CHARACTER_FEE_DECREASE_SPEED = 20
    // VAR_WEAPON_FEE_INCREASE = 21
    // VAR_CHARACTER_FEE_INCREASE = 22
    // VAR_MIN_WEAPON_FEE = 23
    // VAR_MIN_CHARACTER_FEE = 24
    if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
      await game.setVars([19, 20, 21, 22, 23, 24], ['18441348000', '184413480000', '25493330000000', '1327777770000000', '300', '3000']);
    }

    if (network === 'hecomainnet') {
      await game.setVars([19, 20, 21, 22, 23, 24], ['18441348000', '184413480000', '1695750000000', '36011600000000', '300', '3000']);
    }

    if (network === 'okexmainnet') {
      await game.setVars([19, 20, 21, 22, 23, 24], ['18441348000', '184413480000', '1942850000000', '32857860000000', '300', '3000']);
    }

    if (network === 'polygonmainnet') {
      await game.setVars([19, 20, 21, 22, 23, 24], ['18441348000', '184413480000', '11462820000000', '319625540000000', '300', '3000']);
    }

    if (network === 'avaxmainnet' || network === 'avaxmainnet-fork') {
      await game.setVars([19, 20, 21, 22, 23, 24], ['18441348000', '184413480000', '1225641020000000', '18745098020000000', '300', '3000']);
    }

    if (network === 'auroramainnet') {
      await game.setVars([23, 24], ['300', '3000']);
    }
  }
};
