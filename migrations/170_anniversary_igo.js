const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer) {
    await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

    // DEPRECATED

    // const VAR_FIGHT_FLAT_IGO_BONUS = await game.VAR_FIGHT_FLAT_IGO_BONUS();
    // let VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.015', 'ether'); // default
    //
    // if(network === 'bscmainnet') {
    //     VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.01141071429', 'ether');
    // }
    // else if(network === 'hecomainnet') {
    //     VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.01392857143', 'ether');
    // }
    // else if(network === 'okexmainnet') {
    //     VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.01558928571', 'ether');
    // }
    // else if(network === 'polygonmainnet') {
    //     VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.01280357143', 'ether');
    // }
    // else if(network === 'avaxmainnet') {
    //     VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.01928571429', 'ether');
    // }
    // else if(network === 'auroramainnet') {
    //     VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.009214285714', 'ether');
    // }
    //
    // await game.setVar(VAR_FIGHT_FLAT_IGO_BONUS, VALUE_FIGHT_FLAT_IGO_BONUS);
};
