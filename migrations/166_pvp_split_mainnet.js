const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const PvpCore = artifacts.require("PvpCore");
const PvpRankings = artifacts.require("PvpRankings");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");
const ChainlinkRandoms = artifacts.require("ChainlinkRandoms");

module.exports = async function (deployer, network, accounts) {
    const game = await CryptoBlades.deployed();
    const shields = await Shields.deployed();
    const characters = await Characters.deployed();
    const weapons = await Weapons.deployed();

    if (network === 'bscmainnet'
    || network === 'bscmainnet-fork'
    || network === 'hecomainnet'
    || network === 'okexmainnet'
    || network === 'polygonmainnet'
    || network === 'avaxmainnet'
    || network === 'avaxmainnet-fork'
    || network === 'auroramainnet'
    || network === 'skalemainnet' || network === 'coinexmainnet' || network === 'metermainnet'  || network === 'cronosmainnet'
    || network === 'kavamainnet') {
        let randoms = await ChainlinkRandoms.deployed();

        const pvpRankings = await deployProxy(
            PvpRankings,
            [game.address],
            { deployer }
        );

        const pvpCore = await deployProxy(
            PvpCore,
            [game.address, shields.address, randoms.address, pvpRankings.address],
            { deployer }
        );

        await pvpCore.grantRole(await pvpCore.GAME_ADMIN(), accounts[0]);
        await pvpRankings.grantRole(await pvpRankings.GAME_ADMIN(), accounts[0]);
        await pvpCore.grantRole(await pvpCore.GAME_ADMIN(), pvpRankings.address);
        await pvpRankings.grantRole(await pvpRankings.GAME_ADMIN(), pvpCore.address);
        const GAME_ADMIN = await game.GAME_ADMIN();
        await game.grantRole(GAME_ADMIN, pvpCore.address);
        await game.grantRole(GAME_ADMIN, pvpRankings.address);
        await characters.grantRole(await characters.GAME_ADMIN(), pvpCore.address);
        await weapons.grantRole(await weapons.GAME_ADMIN(), pvpCore.address);
        await shields.grantRole(await shields.GAME_ADMIN(), pvpCore.address);
        await pvpRankings.setPvpCoreAddress(pvpCore.address);
        
        const pvpBotAddress = '0xC24658012D08a8A575Aa140C7EE45e83c9100F73';
        await pvpCore.grantRole(await pvpCore.GAME_ADMIN(), pvpBotAddress);
        await pvpRankings.grantRole(await pvpRankings.GAME_ADMIN(), pvpBotAddress);
        await pvpCore.setPvpBotAddress(pvpBotAddress);
    }
};