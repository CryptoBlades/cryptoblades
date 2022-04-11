const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SpecialWeaponsManager = artifacts.require('SpecialWeaponsManager');

module.exports = async function (deployer, network) {
  const specialWeaponsManager = await upgradeProxy(SpecialWeaponsManager.address, SpecialWeaponsManager, {deployer});

  if (network === 'bscmainnet'
    || network === 'bscmainnet-fork'
    || network === 'hecomainnet'
    || network === 'avaxmainnet'
    || network === 'avaxmainnet-fork'
    || network === 'okexmainnet'
    || network === 'polygonmainnet') {
    await specialWeaponsManager.setSpecialWeaponLogo(1, 'https://gateway.ipfs.io/ipfs/QmdhNtnsfQdEbQ2BDevDGZAxRJsV2GLusZpKZCofSSCY8V/heco-sword.png');
    await specialWeaponsManager.setSpecialWeaponDetails(1, 'Blessed be the Gods! We have been victorious in our quest to conquer the Heco Master Builders Competition. In celebration a mighty weapon has been crafted. Trade in your shards to lay claim to this illustrious blade. Limited quantities available.');

    await specialWeaponsManager.setSpecialWeaponLogo(2, 'https://gateway.ipfs.io/ipfs/QmdhNtnsfQdEbQ2BDevDGZAxRJsV2GLusZpKZCofSSCY8V/blazing-mane.png');
    await specialWeaponsManager.setSpecialWeaponDetails(2, 'The searing blade of Emberhearth can only be wielded by those found to be worthy of its power.  Passed on to the leader of the Faisar Fire Knights, it is said to be forged from an aether stone in the blazing inferno of L\'kah, an ancient volcanic dragon lost long ago.\n\nLay claim to this limited, regal weapon celebrating the first teaser and alpha test of CryptoBlades: Kingdoms.');
    await specialWeaponsManager.setSpecialWeaponWebsite(2, 'https://cryptobladeskingdoms.io/');
  }
};
