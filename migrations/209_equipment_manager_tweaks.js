const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const EquipmentManager = artifacts.require("EquipmentManager");

module.exports = async function (deployer, network) {
    await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    await upgradeProxy(EquipmentManager.address, EquipmentManager, { deployer });
};