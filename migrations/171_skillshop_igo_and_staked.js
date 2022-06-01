const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");

module.exports = async function (deployer, network, accounts) {
    let blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
};
