const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const EquipmentManager = artifacts.require("EquipmentManager");
const TokensManager = artifacts.require("TokensManager");

module.exports = async function (deployer, network) {
    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    let VAR_FIGHT_REROLL_PENALTY_PERCENT = await game.VAR_FIGHT_REROLL_PENALTY_PERCENT();
    await game.setVar(VAR_FIGHT_REROLL_PENALTY_PERCENT, 5);
    await upgradeProxy(EquipmentManager.address, EquipmentManager, { deployer });
    await upgradeProxy(TokensManager.address, TokensManager, { deployer });
};