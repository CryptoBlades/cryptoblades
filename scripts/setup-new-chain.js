const SpecialWeaponsManager = artifacts.require('SpecialWeaponsManager');
const Launchpad = artifacts.require('Launchpad');
const CryptoBlades = artifacts.require('CryptoBlades');
const Raid = artifacts.require('Raid1');
const TokensManager = artifacts.require('TokensManager');

module.exports = async (callback) => {
  // ADJUST CONFIGURATION AND RUN WITH: npx truffle exec scripts/setup-new-chain.js --network <network_name>
  // CONFIGURATION

  // payout formula
  const VAR_HOURLY_PAY_PER_FIGHT = '3600000000000000';
  const VAR_PARAM_PAYOUT_INCOME_PERCENT = '100';
  const VAR_PARAM_MAX_FIGHT_PAYOUT = '1000000000000000000';
  const VAR_HOURLY_DISTRIBUTION = '200000000000000000000';
  const VAR_HOURLY_MAX_POWER_AVERAGE = '24000';
  const VAR_PARAM_HOURLY_MAX_POWER_PERCENT = '100';
  const VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS = '1000000';
  const VAR_PARAM_HOURLY_PAY_ALLOWANCE = '200000000000000000000';

  // dynamic mint prices
  const VAR_MINT_WEAPON_FEE_DECREASE_SPEED = '1106480880000';
  const VAR_MINT_CHARACTER_FEE_DECREASE_SPEED = '1106480880000';
  const VAR_WEAPON_FEE_INCREASE = '116571000000000';
  const VAR_CHARACTER_FEE_INCREASE = '1971471600000000';
  const VAR_MIN_WEAPON_FEE = '815';
  const VAR_MIN_CHARACTER_FEE = '7965';

  // token manager token prices
  const skillPrice = '200'; // in cents
  const tokenPrice = '5';  // in cents

  //special weapon event id
  const specialWeaponEventId = '9';

  // raid xp reward
  const raidXpReward = '120';

  // nft storage native fees
  const withdrawFee = '';
  const requestBridgeFee = '';

  // SCRIPT LOGIC

  // payout formula
  const cryptoBlades = await CryptoBlades.deployed();
  console.log('Configuring payout formula...');
  await cryptoBlades.setVars(
    [5,9,12,13,15,16,17,18], 
    [
      VAR_HOURLY_PAY_PER_FIGHT,
      VAR_PARAM_PAYOUT_INCOME_PERCENT,
      VAR_PARAM_MAX_FIGHT_PAYOUT,
      VAR_HOURLY_DISTRIBUTION,
      VAR_HOURLY_MAX_POWER_AVERAGE,
      VAR_PARAM_HOURLY_MAX_POWER_PERCENT,
      VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS,
      VAR_PARAM_HOURLY_PAY_ALLOWANCE
    ]);
  console.log('Payout formula configured.\n');

  // tokens prices
  console.log('Configuring tokens manager...');
  const tokensManager = await TokensManager.deployed();
  await tokensManager.setSkillTokenPrice(skillPrice);
  await tokensManager.setTokenPrice(tokenPrice);
  console.log('Tokens Manager configured.\n');


  // dynamic mint prices
  console.log('Configuring dynamic mint prices...');
  await cryptoBlades.setVars(
    [19,20,21,22,23,24],
    [
      VAR_MINT_WEAPON_FEE_DECREASE_SPEED,
      VAR_MINT_CHARACTER_FEE_DECREASE_SPEED,
      VAR_WEAPON_FEE_INCREASE,
      VAR_CHARACTER_FEE_INCREASE,
      VAR_MIN_WEAPON_FEE,
      VAR_MIN_CHARACTER_FEE
    ]
  )
  console.log('Dynamic mint prices configured.\n');

  // special weapon event id
  console.log('Configuring special weapon event id...');
  const specialWeaponsManager = await SpecialWeaponsManager.deployed();
  let currentId = await specialWeaponsManager.eventCount();
  for(let i = +currentId; i < +specialWeaponEventId; i++) {
    await specialWeaponsManager.incrementEventCount();
  }
  currentId = await specialWeaponsManager.eventCount();
  console.log('Special weapon event id configured. Current id:', currentId.toString(), '\n');

  // launchpad launch id
  // console.log('Configuring launchpad launch id...');
  
  // console.log('Launchpad launch id configured.');

  // raid xp
  console.log('Configuring raid xp...');
  const raid = await Raid.deployed();
  await raid.setXpReward(raidXpReward);
  console.log('Raid xp configured.\n');

  callback();
}