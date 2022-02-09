const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const Treasury = artifacts.require("Treasury");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer, network) {
    await upgradeProxy(Treasury.address, Treasury, { deployer });
    await upgradeProxy(Characters.address, Characters, { deployer });
};