const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Treasury = artifacts.require("Treasury");

module.exports = async function (deployer, network, accounts) {
    await upgradeProxy(Treasury.address, Treasury, { deployer });
};