const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Weapons = artifacts.require('Weapons');
const Characters = artifacts.require('Characters');
const Shields = artifacts.require('Shields');
const Junk = artifacts.require('Junk');
const RaidTrinket = artifacts.require('RaidTrinket');
const KeyLootbox = artifacts.require('KeyLootbox');


module.exports = async function (deployer, network, accounts) {
  let weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
  let characters = await upgradeProxy(Characters.address, Characters, { deployer });
  let shields = await upgradeProxy(Shields.address, Shields, { deployer });
  let junk = await upgradeProxy(Junk.address, Junk, { deployer });
  let raidTrinket = await upgradeProxy(RaidTrinket.address, RaidTrinket, { deployer });
  let keyLootbox = await upgradeProxy(KeyLootbox.address, KeyLootbox, { deployer });

  let weapons_GA = await weapons.GAME_ADMIN();
  let characters_GA = await characters.GAME_ADMIN();
  let shields_GA = await shields.GAME_ADMIN();
  let junk_GA = await junk.GAME_ADMIN();
  let raidTrinket_GA = await raidTrinket.GAME_ADMIN();
  let keyLootbox_GA = await keyLootbox.GAME_ADMIN();

  const bscDeployerAddress = "0xa2bB660A6A3Bb5c74E36415ffe5D4862eFfc417A";
  const altChainsDeployerAddress = "0x15C899E13be4db3bDaa518A4bb29Cbb9F4e7B8Be";
  let networkName = 'bsc';

  if(network === 'development') {
    await weapons.grantRole(weapons_GA, accounts[0]);
    await characters.grantRole(characters_GA, accounts[0]);
    await shields.grantRole(shields_GA, accounts[0]);
    await junk.grantRole(junk_GA, accounts[0]);
    await raidTrinket.grantRole(raidTrinket_GA, accounts[0]);
    await keyLootbox.grantRole(keyLootbox_GA, accounts[0]);
  }
  else if(network === 'bscmainnet' || network === 'bsctestnet') {
    await weapons.grantRole(weapons_GA, bscDeployerAddress);
    await characters.grantRole(characters_GA, bscDeployerAddress);
    await shields.grantRole(shields_GA, bscDeployerAddress);
    await junk.grantRole(junk_GA, bscDeployerAddress);
    await raidTrinket.grantRole(raidTrinket_GA, bscDeployerAddress);
    await keyLootbox.grantRole(keyLootbox_GA, bscDeployerAddress);
  }
  else {
    if(network === 'hecomainnet' || network === 'hecotestnet') {
      networkName = 'heco';
    }
    else if(network === 'okexmainnet' || network === 'okextestnet') {
      networkName = 'oec';
    }
    else if(network === 'polygonmainnet' || network === 'polygontestnet') {
      networkName = 'polygon';
    }
    else if(network === 'avaxmainnet' || network === 'avaxtestnet') {
      networkName = 'avax';
    }
    else if(network === 'auroramainnet' || network === 'auroratestnet') {
      networkName = 'aurora';
    }

    await weapons.grantRole(weapons_GA, altChainsDeployerAddress);
    await characters.grantRole(characters_GA, altChainsDeployerAddress);
    await shields.grantRole(shields_GA, altChainsDeployerAddress);
    await junk.grantRole(junk_GA, altChainsDeployerAddress);
    await raidTrinket.grantRole(raidTrinket_GA, altChainsDeployerAddress);
    await keyLootbox.grantRole(keyLootbox_GA, altChainsDeployerAddress);
  }

  await weapons.setBaseURI(`https://testapi.cryptoblades.io/nfts/view/${networkName}/cb-weapon/`);
  await characters.setBaseURI(`https://testapi.cryptoblades.io/nfts/view/${networkName}/cb-character/`);
  await shields.setBaseURI(`https://testapi.cryptoblades.io/nfts/view/${networkName}/cb-shield/`);
};
