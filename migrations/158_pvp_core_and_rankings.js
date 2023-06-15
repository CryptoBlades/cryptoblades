const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const PvpCore = artifacts.require("PvpCore");
const PvpRankings = artifacts.require("PvpRankings");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");
const DummyRandoms = artifacts.require("DummyRandoms");
const ChainlinkRandoms = artifacts.require("ChainlinkRandoms");

module.exports = async function (deployer, network, accounts) {
    const game = await CryptoBlades.deployed();
    const shields = await Shields.deployed();
    const characters = await Characters.deployed();
    const weapons = await Weapons.deployed();

    if (network === "development"
    || network === "development-fork"
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet'
    || network === 'avaxtestnet'
    || network === 'avaxtestnet-fork'
    || network === 'auroratestnet'
    || network === 'kavatestnet'
    || network === 'skaletestnet' || network === 'coinextestnet' || network === 'metertestnet' || network === 'opsidetestnet') {
        let randoms;

        if (network === "development" || network === "development-fork") {
            randoms = await DummyRandoms.deployed();
        } else {
            randoms = await ChainlinkRandoms.deployed();
        }

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
    }
};