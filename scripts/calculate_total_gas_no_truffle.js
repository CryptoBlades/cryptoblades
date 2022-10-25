const fetch = require("node-fetch");
const BigNumber = require('bignumber.js');
const fs = require('fs');

const saveResults = (results) => {
  fs.writeFileSync('scripts/results.json', JSON.stringify(results), function(err, data){
    // Display the file content
    console.log(data);
  });
}

const loadResults = (contracts) => {
  const results = [];
  if(!fs.existsSync('scripts/results.json')) {
    for(let c of contracts) {
      results.push({
        'Address': c[1],
        'Name': c[0],
        'Gas Used (BNB)': 0,
        'Tx Count': 0
      });
    }

    return results;
  }
  return JSON.parse(fs.readFileSync('scripts/results.json', function(err, data){
    // Display the file content
    console.log(data);
  }));
}

const calculate = async () => {

  const contracts = [
    [ 'CryptoBlades', '0x39Bea96e13453Ed52A734B6ACEeD4c41F57B2271' ],
    [ 'TokensManager', '0xCE34a87173130eF691ff81feF1a6E8b8a9DAcA6F' ],
    [ 'Blacksmith', '0x970Ea2c182199A38ed6d991B730A5a9638B1a399' ],
    [ 'PvpCore', '0x386088468D67333d393594C8427f15A64fa8896c' ],
    [ 'PvpRankings', '0x76f3Ba06d1C4994122cA81998dC405A17010AE81' ],
    [ 'Treasury', '0x812Fa2f7d89e5d837450702bd51120920dccaA99' ],
    [ 'Characters', '0xc6f252c2CdD4087e30608A35c022ce490B58179b' ],
    [ 'Weapons', '0x7E091b0a220356B157131c831258A9C98aC8031A' ],
    [ 'Raid1', '0x1067d34D7bEBe2BE81657e8a2E3CFEBb0161F96b' ],
    [ 'SimpleQuests', '0xD6CDf4072EB6bcF10ef1b715aaA0fDF755B52327' ],
    [ 'BurningManager', '0xbE555D81117EEe690ACBaC54aF735AC32d763Fd2' ],
    [ 'KeyLootbox', '0x4AF4E207F4e9217352af4570c78581af2F6cBb40' ],
    [ 'RaidTrinket', '0x16680baFe395022Ae73755946fe5D484118Fe035' ],
    [ 'Junk', '0x358Ce1ebC87300c3A75ED51411c17AC3a9CFa11c' ],
    [ 'Shields', '0xf9E9F6019631bBE7db1B71Ec4262778eb6C3c520' ],
    [ 'Garrison', '0x0D0Ebe222F8Fc996cC1BcF497d653082708b45E4' ],
    [ 'PartnerVault', '0x08C536d43cE3d8FBc89444D729F7cD04332A4cdE' ],
    [ 'NFTStorage', '0x32Abf3872b1399E8C17FCA1c574A02096B339e3F' ],
    [ 'ERC20Bridge', '0x5C41Fb66849aba563D1b6718772fb01ceb018c71' ],
    [
      'WeaponBridgeProxyContract',
      '0x1779E22fd70fB68822c32b6AE2177b33C555795b'
    ],
    [
      'ShieldBridgeProxyContract',
      '0xa27e8336A5821F6dF3ee32146882002E3fa00832'
    ],
    [
      'CharactersBridgeProxyContract',
      '0xa53735eFc648b2185631965a37Bc1E48041Dec06'
    ],
    [ 'Promos', '0xE6259bd51bd2cCa4078C4b188B8E966E995822b9' ],
    [
      'ValorERC20BridgeProxyContract',
      '0x7f7a952B461084dceD3A552Ff4FbB0F1260E874d'
    ],
    [ 'SkillToken', '0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab' ],
    [ 'KingToken', '0x0ccd575bf9378c06f6dca82f8122f570769f00c2' ],
    [ 'ValorToken', '0x4Db374Da614c3653DdEaD0cB8f96BD90c87602C1' ],
    [ 'NFTMarket', '0x90099dA42806b21128A094C713347C7885aF79e2' ],
    [ 'PvpArena', '0x8ADB6c9f7FAdB959a9847fd9Bd0ED503446942Ca' ],
    [
      'SpecialWeaponsManager',
      '0xB244c6d4059f5357Cd6558A041d2A7d622cAD555'
    ],
    [ 'CBKLand', '0xd3b5df75a4d0d87Add79A5bdAB2f865928F7Fc8e' ],
    [ 'Merchandise', '0x168470C8A5a244aEE5a01B8D812F2069dB2038aE' ],
    [ 'CBKLandSale', '0x95047Fd99EF9dF86Dc11c051102884fA6e0eddbe' ],
    [
      'CBKLandBridgeProxyContract',
      '0x95f1AD7d60dC5857637Bca4651c547B6203c11Ec'
    ],
    [
      'CBKLandT1StakingRewardsUpgradeable',
      '0x4d777b2B187dc41d1c8Ec6E9451F6Eb2a0Ce7DCa'
    ],
    [
      'CBKLandT2StakingRewardsUpgradeable',
      '0xb7F9063B6D7A9886e3adDEa9B8f858c3080A2163'
    ],
    [
      'CBKLandT3StakingRewardsUpgradeable',
      '0x960b824c67D8D6c48A6d0362Cc96bE980ada25d7'
    ],
    [
      'CharacterCosmetics',
      '0xd37f8d36c43F4EeE9DB91BEAD21ee9251F287925'
    ],
    [
      'CharacterEarthTraitChangeConsumables',
      '0x5A76Ba4f13eA0D1F0dB22CdfE2420Df25D46a3dC'
    ],
    [
      'CharacterFireTraitChangeConsumables',
      '0xA1fa3E149c3e7d5af8Cd1EFED039FC64ff8260a3'
    ],
    [
      'CharacterLightningTraitChangeConsumables',
      '0x118de12Cc76615d6E0e8F883ca9DAE5F6F503940'
    ],
    [
      'CharacterWaterTraitChangeConsumables',
      '0x9e6b9853cF82f169D6D64d0272E0c6407275Eb93'
    ],
    [
      'CharacterRenameTagConsumables',
      '0x06c1c043434AC4B68b2f8A5e4d9fD92238eCC0e3'
    ],
    [
      'SkillERC20BridgeProxyContract',
      '0x9dDC408b7041Cf81d3a5B46a843bf50e03a1C8d7'
    ],
    [
      'SkillStakingRewardsUpgradeable',
      '0xd6b2D8f59Bf30cfE7009fB4fC00a7b13Ca836A2c'
    ],
    [
      'SkillStakingRewardsUpgradeable90',
      '0xc42dF5397B3C0B45DeDaCB83F7aDb1F30B73097d'
    ],
    [
      'SkillStakingRewardsUpgradeable180',
      '0x3C06533B42A802f3Ac0E770CCBBeA9fa7Cae9572'
    ],
    [ 'WeaponCosmetics', '0xc8E0bE1554618b0F6dA8f83CE66A9c3aE1Df8038' ],
    [
      'WeaponRenameTagConsumables',
      '0xEcDC66Ca26e2B90d1e10AFAA162164f685f51c81'
    ],
    [
      'VB - WeaponStaking',
      '0x928516345463816B76194E0D8e4b6EB0f2C9c10E'
    ],
    [ 'VB - Village', '0x50dC3f8395eB76A1B99E9509ED52F96FCB11b037' ],
    [ 'VB - SkillStaking', '0xFACCb36359AC41661EE3135d55B190f4486c5b34' ],
    [ 'VB - KingVault', '0xEBf064231996F322E665EA7D2a48E609d2d5cAB7' ],
    [
      'VB - CharacterStaking',
      '0xCdd727622832353EdB81AddfDc2b1aE09C3bF44f'
    ],
    [ 'VB - KingStaking', '0x2411a6A3Ce5cCfc649B1619EDf7105fa4BcE71eD' ],
    [ 'Migrations', '0x5288E3551AB01cAdcAA25d24800e1B9c342C3016' ],
    [
      'SkillStakingRewardsUpgradeable60',
      '0x4B4BaEb52C1A2679e13D9D6D9680b03308216244'
    ],
    [
      'ValorStakingRewardsUpgradeable',
      '0xC897e1dcd2E3f865dFE253dcF10c750B08fFebEC'
    ],
    [
      'LPStakingRewardsUpgradeableValor',
      '0x5C76Ea3A52C0b7C8378420f00F68089C12F4120E'
    ],
    [
      'LP2StakingRewardsUpgradeableValor',
      '0xf521272c491a2eA2b613e39C6D5167E8382786ED'
    ]
  ]

  // starting block 21794337
  const fromBlock = 22447067;
  const toBlock = 22475052;
  const blockInterval = 2300;
  const blockIntervalsAmount = ((toBlock - fromBlock) / blockInterval) + 1;
  const offset = 8000;
  const intervalGas = new Array(contracts.length).fill(new BigNumber(0));

  const results = loadResults(contracts);

  let totalGas = new BigNumber(0);


  for(let [index, contract] of contracts.entries()) {
    let gasForContract = new BigNumber(0);
    let txCount = 0;
    totalGas = totalGas.plus(new BigNumber(results[index]['Gas Used (BNB)'])*1e18);
    
    for(let i = 1; i < blockIntervalsAmount; i++) {
      let hasResults = true;
      let page = 1;
      console.log('Fetching block', fromBlock + ((i - 1) * blockInterval), fromBlock + (i * blockInterval) - 1);
      while(hasResults) {
        let apiEndpoint = `https://api.bscscan.com/api?module=account&action=txlist&address=${contract[1]}&startblock=${fromBlock + ((i - 1) * blockInterval)}&endblock=${fromBlock + (i * blockInterval) - 1}&page=${page}&offset=${offset}&sort=asc&apikey=Y2NZZRS4ZR4DF421IVKTPWR1V7EP63QW56`;
        await fetch(apiEndpoint).then((response) => response.json()).then((transactions) => {
          if(transactions.status === '0') {
            console.log(contract[0], 'No results for page:', page);
            hasResults = false;
          }
          else {
            console.log(contract[0], 'fetched results for page:', page);
            for(let tx of transactions.result) {
              gasForContract = gasForContract?.plus(new BigNumber(tx.gasPrice).multipliedBy(tx.gasUsed));
              txCount++;
            }
          }
        });
        page++;
      }
      intervalGas[i - 1] = intervalGas[i - 1]?.plus(gasForContract);
    }

    // results.push({
    //     'Address': contract[1],
    //     'Name': contract[0],
    //     'Gas Used (BNB)': gasForContract.toString()/1e18,
    //     'Tx Count': txCount
    // });

    console.log(index);
    results[index]['Gas Used (BNB)'] = +results[index]['Gas Used (BNB)'] + gasForContract.toString()/1e18;
    results[index]['Tx Count'] = +results[index]['Tx Count'] + txCount;

    totalGas = totalGas?.plus(gasForContract);
    console.log('Total gas:', totalGas.toString()/1e18);
  }

  saveResults(results);

  results.sort((a, b) => { return +b['Gas Used (BNB)'] - +a['Gas Used (BNB)']});
  console.table(results);
  console.log('Total gas:', totalGas.toString()/1e18);
  console.log(new Date().toUTCString());

  //console.log(intervalGas.map(x => x.toString()/1e18));
  
}

calculate();
