const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {
    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    
    const paramMaxFightPayout = await game.VAR_PARAM_MAX_FIGHT_PAYOUT();
    await game.setVar(paramMaxFightPayout, web3.utils.toWei('0.1', 'ether'));
};