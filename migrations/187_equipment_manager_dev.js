const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const EquipmentManager = artifacts.require("EquipmentManager");

module.exports = async function (deployer, network, accounts) {
    await upgradeProxy(EquipmentManager.address, EquipmentManager, { deployer });
};