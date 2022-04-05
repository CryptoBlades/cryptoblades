const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const PvpCore = artifacts.require("PvpCore");
const PvpAddons = artifacts.require("PvpAddons");
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
    || network === 'avaxtestnet-fork' || network === 'auroratestnet') {
        let randoms;

        if (network === "development" || network === "development-fork") {
            randoms = await DummyRandoms.deployed();
        } else {
            randoms = await ChainlinkRandoms.deployed();
        }

        const pvpAddons = await deployProxy(
            PvpAddons,
            [game.address],
            { deployer }
        );

        const pvpCore = await deployProxy(
            PvpCore,
            [game.address, shields.address, randoms.address, pvpAddons.address],
            { deployer }
        );

        await pvpCore.grantRole(await pvpCore.GAME_ADMIN(), accounts[0]);
        await pvpAddons.grantRole(await pvpAddons.GAME_ADMIN(), accounts[0]);
        await pvpCore.grantRole(await pvpCore.GAME_ADMIN(), pvpAddons.address);
        await pvpAddons.grantRole(await pvpAddons.GAME_ADMIN(), pvpCore.address);
        const GAME_ADMIN = await game.GAME_ADMIN();
        await game.grantRole(GAME_ADMIN, pvpCore.address);
        await game.grantRole(GAME_ADMIN, pvpAddons.address);
        await characters.grantRole(await characters.GAME_ADMIN(), pvpCore.address);
        await weapons.grantRole(await weapons.GAME_ADMIN(), pvpCore.address);
        await shields.grantRole(await shields.GAME_ADMIN(), pvpCore.address);
        await pvpAddons.setPvpCoreAddress(pvpCore.address);
    }
};