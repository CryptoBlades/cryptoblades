const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {

    let game = await CryptoBlades.deployed();

    // we apply some variables per-chain before upgrading

    const VAR_HOURLY_INCOME = await game.VAR_HOURLY_INCOME();
    const VAR_HOURLY_POWER_AVERAGE = await game.VAR_HOURLY_POWER_AVERAGE();
    const VAR_UNCLAIMED_SKILL = 14;
    const VAR_HOURLY_MAX_POWER_AVERAGE = 15;
    const VAR_PARAM_HOURLY_MAX_POWER_PERCENT = 16;
    const VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS = 17;
    const VAR_PARAM_HOURLY_PAY_ALLOWANCE = 18;
    const VAR_PARAM_PAYOUT_INCOME_PERCENT = await game.VAR_PARAM_PAYOUT_INCOME_PERCENT();
    const VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT = await game.VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT();
    const VAR_PARAM_MAX_FIGHT_PAYOUT = await game.VAR_PARAM_MAX_FIGHT_PAYOUT();
    
    const VAR_HOURLY_PAY_PER_FIGHT = await game.VAR_HOURLY_PAY_PER_FIGHT();
    let VALUE_HOURLY_PAY_PER_FIGHT = web3.utils.toWei('0.0005', 'ether'); // default on new chain

    if(network === 'bscmainnet') {
        VALUE_HOURLY_PAY_PER_FIGHT = web3.utils.toWei('0.007', 'ether');
        await game.setVars(
            [
                VAR_HOURLY_INCOME,
                VAR_HOURLY_POWER_AVERAGE,
                VAR_UNCLAIMED_SKILL,
                VAR_HOURLY_MAX_POWER_AVERAGE,
                VAR_PARAM_HOURLY_MAX_POWER_PERCENT,
                VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS,
                VAR_PARAM_HOURLY_PAY_ALLOWANCE,
                VAR_PARAM_PAYOUT_INCOME_PERCENT,
                VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT
            ],
            [
                web3.utils.toWei('100.0', 'ether'), // reward pool
                30000, // power avg
                web3.utils.toWei('10000.0', 'ether'), // unclaimed counter (intentionally inflated here)
                30000, // max power avg
                100, // % max power to set as avg
                1000, // 40stam fights to consider updating power avg
                web3.utils.toWei('3.125', 'ether'), // hourly allowance
                75, // % of income going to reward pool
                10 // pay-per-fight * this to set claim limit
            ]
        );
    }
    else if(network === 'hecomainnet') {
        VALUE_HOURLY_PAY_PER_FIGHT = web3.utils.toWei('0.0002', 'ether');
        await game.setVars(
            [
                VAR_HOURLY_INCOME,
                VAR_HOURLY_POWER_AVERAGE,
                VAR_UNCLAIMED_SKILL,
                VAR_HOURLY_MAX_POWER_AVERAGE,
                VAR_PARAM_HOURLY_MAX_POWER_PERCENT,
                VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS,
                VAR_PARAM_HOURLY_PAY_ALLOWANCE,
                VAR_PARAM_PAYOUT_INCOME_PERCENT,
                VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT
            ],
            [
                web3.utils.toWei('100.0', 'ether'), // reward pool
                16500, // power avg
                web3.utils.toWei('1000.0', 'ether'), // unclaimed counter (intentionally inflated here)
                16500, // max power avg
                100, // % max power to set as avg
                1000, // 40stam fights to consider updating power avg
                web3.utils.toWei('0.39', 'ether'), // hourly allowance
                75, // % of income going to reward pool
                57 // pay-per-fight * this to set claim limit
            ]
        );
    }
    else if(network === 'okexmainnet') {
        VALUE_HOURLY_PAY_PER_FIGHT = web3.utils.toWei('0.0002', 'ether');
        await game.setVars(
            [
                VAR_HOURLY_INCOME,
                VAR_HOURLY_POWER_AVERAGE,
                VAR_UNCLAIMED_SKILL,
                VAR_HOURLY_MAX_POWER_AVERAGE,
                VAR_PARAM_HOURLY_MAX_POWER_PERCENT,
                VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS,
                VAR_PARAM_HOURLY_PAY_ALLOWANCE,
                VAR_PARAM_PAYOUT_INCOME_PERCENT,
                VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT
            ],
            [
                web3.utils.toWei('10.0', 'ether'), // reward pool
                13700, // power avg
                web3.utils.toWei('1000.0', 'ether'), // unclaimed counter (intentionally inflated here)
                13700, // max power avg
                100, // % max power to set as avg
                200, // 40stam fights to consider updating power avg
                web3.utils.toWei('0.09375', 'ether'), // hourly allowance
                75, // % of income going to reward pool
                57 // pay-per-fight * this to set claim limit
            ]
        );
    }
    else if(network === 'polygonmainnet') {
        VALUE_HOURLY_PAY_PER_FIGHT = web3.utils.toWei('0.0003', 'ether');
        await game.setVars(
            [
                VAR_HOURLY_INCOME,
                VAR_HOURLY_POWER_AVERAGE,
                VAR_UNCLAIMED_SKILL,
                VAR_HOURLY_MAX_POWER_AVERAGE,
                VAR_PARAM_HOURLY_MAX_POWER_PERCENT,
                VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS,
                VAR_PARAM_HOURLY_PAY_ALLOWANCE,
                VAR_PARAM_PAYOUT_INCOME_PERCENT,
                VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT
            ],
            [
                web3.utils.toWei('10.0', 'ether'), // reward pool
                3850, // power avg
                web3.utils.toWei('1000.0', 'ether'), // unclaimed counter (intentionally inflated here)
                3850, // max power avg
                100, // % max power to set as avg
                200, // 40stam fights to consider updating power avg
                web3.utils.toWei('0.0625', 'ether'), // hourly allowance
                75, // % of income going to reward pool
                10 // pay-per-fight * this to set claim limit
            ]
        );
    }
    else { // DEV & NEW CHAIN DEFAULTS
        // default PAY_PER_FIGHT is set earlier on definition (0.0005)
        await game.setVars(
            [
                VAR_HOURLY_INCOME,
                VAR_HOURLY_POWER_AVERAGE,
                //VAR_UNCLAIMED_SKILL,
                VAR_HOURLY_MAX_POWER_AVERAGE,
                VAR_PARAM_HOURLY_MAX_POWER_PERCENT,
                VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS,
                VAR_PARAM_HOURLY_PAY_ALLOWANCE,
                VAR_PARAM_PAYOUT_INCOME_PERCENT,
                VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT
            ],
            [
                web3.utils.toWei('10.0', 'ether'), // reward pool
                1250, // power avg
                //web3.utils.toWei('0.0', 'ether'), // unclaimed counter
                1250, // max power avg
                100, // % max power to set as avg
                100, // 40stam fights to consider updating power avg
                web3.utils.toWei('0.2', 'ether'), // hourly allowance
                75, // % of income going to reward pool
                57 // pay-per-fight * this to set claim limit
            ]
        );
    }

    // now for the upgrade and a few final variables set

    game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

    const VAR_HOURLY_DISTRIBUTION = await game.VAR_HOURLY_DISTRIBUTION();
    const VALUE_HOURLY_DISTRIBUTION = await game.vars(VAR_PARAM_HOURLY_PAY_ALLOWANCE);

    const VAR_DAILY_MAX_CLAIM = await game.VAR_DAILY_MAX_CLAIM();
    const VALUE_PARAM_DAILY_CLAIM_FIGHTS_LIMIT = await game.vars(VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT);

    await game.setVars(
        [
            VAR_HOURLY_PAY_PER_FIGHT,
            VAR_HOURLY_DISTRIBUTION,
            VAR_DAILY_MAX_CLAIM,
            VAR_PARAM_MAX_FIGHT_PAYOUT
        ],
        [
            VALUE_HOURLY_PAY_PER_FIGHT,
            VALUE_HOURLY_DISTRIBUTION,
            web3.utils.toBN(VALUE_HOURLY_PAY_PER_FIGHT).mul(VALUE_PARAM_DAILY_CLAIM_FIGHTS_LIMIT),
            web3.utils.toWei('0.02', 'ether') // hard upper limit on 40stam earns
        ]
    );
};