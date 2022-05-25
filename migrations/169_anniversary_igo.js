const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {
    let game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

    const VAR_FIGHT_FLAT_IGO_BONUS = await game.VAR_FIGHT_FLAT_IGO_BONUS();
    let VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.0005', 'ether'); // default

    if(network === 'bscmainnet') {
        VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.007', 'ether');
    }
    else if(network === 'hecomainnet') {
        VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.007', 'ether');
    }
    else if(network === 'okexmainnet') {
        VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.007', 'ether');
    }
    else if(network === 'polygonmainnet') {
        VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.007', 'ether');
    }
    else if(network === 'avaxmainnet') {
        VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.007', 'ether');
    }
    else if(network === 'auroramainnet') {
        VALUE_FIGHT_FLAT_IGO_BONUS = web3.utils.toWei('0.007', 'ether');
    }
    
    await game.setVar(VAR_FIGHT_FLAT_IGO_BONUS, VALUE_FIGHT_FLAT_IGO_BONUS);
};
