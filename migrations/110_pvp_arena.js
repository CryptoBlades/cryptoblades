const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const PvpArena = artifacts.require("PvpArena");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");
const Raid1 = artifacts.require("Raid1");
const DummyRandoms = artifacts.require("DummyRandoms");
const ChainlinkRandoms = artifacts.require("ChainlinkRandoms");

module.exports = async function (deployer, network, accounts) {
    const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    const shields = await upgradeProxy(Shields.address, Shields, { deployer });

    let randoms;

    if (network === "development" || network === "development-fork") {
        randoms = await DummyRandoms.deployed();
    } else {
        randoms = await ChainlinkRandoms.deployed();
    }

    const pvpArena = await deployProxy(
        PvpArena,
        [game.address, shields.address, randoms.address],
        { deployer }
    );

    await pvpArena.grantRole(await pvpArena.GAME_ADMIN(), accounts[0]);

    await upgradeProxy(Characters.address, Characters, { deployer });
    await upgradeProxy(Weapons.address, Weapons, { deployer });
    await upgradeProxy(Raid1.address, Raid1, { deployer });

    const GAME_ADMIN = await game.GAME_ADMIN();
    await game.grantRole(GAME_ADMIN, pvpArena.address);
};