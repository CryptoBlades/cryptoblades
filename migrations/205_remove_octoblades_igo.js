const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network) {
    const game = await CryptoBlades.deployed();
    if(network === 'bscmainnet') {
        const VAR_FIGHT_FLAT_IGO_BONUS = await game.VAR_FIGHT_FLAT_IGO_BONUS();
        await game.setVar(VAR_FIGHT_FLAT_IGO_BONUS, 0);
    }
    await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
};