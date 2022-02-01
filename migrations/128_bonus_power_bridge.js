const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const Characters = artifacts.require("Characters");
const NFTStorage = artifacts.require("NFTStorage");

module.exports = async function (deployer, network) {
    await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
    await upgradeProxy(Characters.address, Characters, { deployer });
};