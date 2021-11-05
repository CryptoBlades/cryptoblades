const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {

    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    
    const VAR_HOURLY_POWER_AVERAGE = await game.VAR_HOURLY_POWER_AVERAGE();
    const currentAverage = await game.vars(VAR_HOURLY_POWER_AVERAGE);

    const VAR_HOURLY_MAX_POWER_AVERAGE = await game.VAR_HOURLY_MAX_POWER_AVERAGE();
    const VAR_PARAM_HOURLY_MAX_POWER_PERCENT = await game.VAR_PARAM_HOURLY_MAX_POWER_PERCENT();
    const VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS = await game.VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS();
    const VAR_PARAM_HOURLY_PAY_ALLOWANCE = await game.VAR_PARAM_HOURLY_PAY_ALLOWANCE();


    await game.setVars(
        [
            VAR_HOURLY_MAX_POWER_AVERAGE,
            VAR_PARAM_HOURLY_MAX_POWER_PERCENT,
            VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS,
            VAR_PARAM_HOURLY_PAY_ALLOWANCE
        ],
        [
            currentAverage == 0 ? 15000 : currentAverage,
            100,
            1000,
            web3.utils.toWei('1.0', 'ether')
        ]
    );
    

    if (network === 'development' || network === 'development-fork') {
        const VAR_HOURLY_PAY_PER_FIGHT = await game.VAR_HOURLY_PAY_PER_FIGHT();
        await game.setVar(VAR_HOURLY_PAY_PER_FIGHT, web3.utils.toWei('0.05', 'ether'));

        const VAR_HOURLY_INCOME = await game.VAR_HOURLY_INCOME();
        await game.setVar(VAR_HOURLY_INCOME, web3.utils.toWei('1.0', 'ether'));
    }
};