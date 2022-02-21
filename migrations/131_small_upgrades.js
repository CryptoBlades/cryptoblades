const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const Treasury = artifacts.require("Treasury");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const PvpArena = artifacts.require("PvpArena");
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network) {
    await upgradeProxy(Treasury.address, Treasury, { deployer });
    await upgradeProxy(Characters.address, Characters, { deployer });
    await upgradeProxy(Weapons.address, Weapons, { deployer });
    await upgradeProxy(PvpArena.address, PvpArena, { deployer });
    await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
};