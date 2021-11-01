const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');


const CryptoBlades = artifacts.require("CryptoBlades");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");
const Blacksmith = artifacts.require("Blacksmith");
const Merchandise = artifacts.require("Merchandise");

module.exports = async function (deployer, network, accounts) {
	
    const game = await CryptoBlades.deployed();
    const blacksmith = await Blacksmith.deployed();
    const LINK_SKILL_ORACLE_2 = await blacksmith.LINK_SKILL_ORACLE_2();
    const skillOracle2 = await blacksmith.getLink(LINK_SKILL_ORACLE_2);
    const merch = await deployProxy(Merchandise, [game.address, skillOracle2], { deployer });

    if (network === 'development' || network === 'development-fork') {
        // set item prices
    }
};