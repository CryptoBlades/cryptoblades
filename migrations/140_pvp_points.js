const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PvpArena = artifacts.require("PvpArena");

module.exports = async function (deployer, network) {

    const pvp = await upgradeProxy(PvpArena.address, PvpArena, { deployer });
};