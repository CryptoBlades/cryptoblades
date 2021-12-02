const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Treasury = artifacts.require("Treasury");

module.exports = async function (deployer, network, accounts) {
    const treasury = await upgradeProxy(Treasury.address, Treasury, { deployer });
    // 1/86400 = 0.00001157407 per second = 1 (100%) per day
    await treasury.setMultiplierUnit('86400');
    await treasury.setDefaultSlippage('5');
};