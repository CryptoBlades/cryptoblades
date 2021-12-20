const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const PvpArena = artifacts.require("PvpArena");
const Shields = artifacts.require("Shields");
const Blacksmith = artifacts.require("Blacksmith");

module.exports = async function (deployer, network, accounts) {
    const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
    const ITEM_SHIELD = await blacksmith.ITEM_SHIELD();
    await blacksmith.setFlatPriceOfItem(ITEM_SHIELD, web3.utils.toWei('3.0', 'ether'));

    if (network === "development"
    || network === "development-fork"
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet'
    || network === 'avaxtestnet'
    || network === 'avaxtestnet-fork') {
        await upgradeProxy(PvpArena.address, PvpArena, { deployer });
    }
    await upgradeProxy(Shields.address, Shields, { deployer });
};
