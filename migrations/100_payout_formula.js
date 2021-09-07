const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const NFTMarket = artifacts.require("NFTMarket");

module.exports = async function (deployer, network, accounts) {
    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    let varFields = [
        await game.VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT(),
        await game.VAR_PARAM_PAYOUT_INCOME_PERCENT(),
        await game.VAR_HOURLY_PAY_PER_FIGHT(),
        await game.VAR_HOURLY_POWER_AVERAGE(),
        await game.VAR_DAILY_MAX_CLAIM(),
        await game.VAR_HOURLY_TIMESTAMP(),
    ]
    let varValues = [
        29, // VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT
        50, // VAR_PARAM_PAYOUT_INCOME_PERCENT
        250000000000000, // VAR_HOURLY_PAY_PER_FIGHT (0.00025 ether)
        15000, // VAR_HOURLY_POWER_AVERAGE
        7250000000000000,// VAR_DAILY_MAX_CLAIM
        Date.now()// VAR_HOURLY_TIMESTAMP
    ];
    await game.setVars(varFields, varValues);
    
    const market = await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
    const GAME_ADMIN = await game.GAME_ADMIN();
    await game.grantRole(GAME_ADMIN, market.address);
};