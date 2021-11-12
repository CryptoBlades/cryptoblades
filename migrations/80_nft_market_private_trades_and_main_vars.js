const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTMarket = artifacts.require("NFTMarket");
const CryptoBlades = artifacts.require("CryptoBlades");
const Raid1 = artifacts.require("Raid1");

module.exports = async function (deployer) {
  await upgradeProxy(Raid1.address, Raid1, { deployer });
  const market = await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
  const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    let varFields = [
        await game.VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT(),
        await game.VAR_PARAM_PAYOUT_INCOME_PERCENT(),
        await game.VAR_HOURLY_PAY_PER_FIGHT(),
        await game.VAR_HOURLY_POWER_AVERAGE(),
        await game.VAR_DAILY_MAX_CLAIM(),
        await game.VAR_CLAIM_DEPOSIT_AMOUNT(),
        await game.VAR_PARAM_DAILY_CLAIM_DEPOSIT_PERCENT(),
    ]
    let varValues = [
        29, // VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT
        50, // VAR_PARAM_PAYOUT_INCOME_PERCENT
        250000000000000, // VAR_HOURLY_PAY_PER_FIGHT (0.00025 ether)
        15000, // VAR_HOURLY_POWER_AVERAGE
        7250000000000000,// VAR_DAILY_MAX_CLAIM
        web3.utils.toWei('1', 'ether'),//VAR_CLAIM_DEPOSIT_AMOUNT
        10,//VAR_PARAM_DAILY_CLAIM_DEPOSIT_PERCENT
    ];
    await game.setVars(varFields, varValues);

    const GAME_ADMIN = await game.GAME_ADMIN();
    await game.grantRole(GAME_ADMIN, market.address);
};
