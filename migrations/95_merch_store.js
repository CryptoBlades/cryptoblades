const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Blacksmith = artifacts.require("Blacksmith");
const Merchandise = artifacts.require("Merchandise");

module.exports = async function (deployer, network, accounts) {
	
    const game = await CryptoBlades.deployed();
    const blacksmith = await Blacksmith.deployed();
    const LINK_SKILL_ORACLE_2 = await blacksmith.LINK_SKILL_ORACLE_2();
    const skillOracle2 = await blacksmith.getLink(LINK_SKILL_ORACLE_2);
    const merch = await deployProxy(Merchandise, [game.address, skillOracle2], { deployer });
    const GAME_ADMIN = await game.GAME_ADMIN();
    await game.grantRole(GAME_ADMIN, merch.address);

    if (network === 'development' || network === 'development-fork') {
        const MERCH_GAME_ADMIN = await merch.GAME_ADMIN();
        await merch.grantRole(MERCH_GAME_ADMIN, accounts[0]);
        // set item prices
        await merch.setItemPrice(1,199); //$1.99
        await merch.setItemPrice(2,999); //$9.99
        await merch.setItemPrice(3,2499); //$24.99
    }
};