const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const PvpArena = artifacts.require("PvpArena");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");
const Raid1 = artifacts.require("Raid1");
const DummyRandoms = artifacts.require("DummyRandoms");
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
    || network === 'avaxmainnet' || network === 'auroramainnet'
    || network === 'avaxmainnet-fork') {
        let randoms = await ChainlinkRandoms.deployed();

        const pvpArena = await deployProxy(
            PvpArena,
            [game.address, shields.address, randoms.address],
            { deployer }
        );

        await pvpArena.grantRole(await pvpArena.GAME_ADMIN(), accounts[0]);
        const GAME_ADMIN = await game.GAME_ADMIN();
        await game.grantRole(GAME_ADMIN, pvpArena.address);

        await characters.grantRole(await characters.GAME_ADMIN(), pvpArena.address);
        await weapons.grantRole(await weapons.GAME_ADMIN(), pvpArena.address);
        await shields.grantRole(await shields.GAME_ADMIN(), pvpArena.address);
    }
};