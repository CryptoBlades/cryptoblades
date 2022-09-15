const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const EquipmentManager = artifacts.require("EquipmentManager");

module.exports = async function (deployer, network, accounts) {
  
    let equip = await deployProxy(EquipmentManager, [], { deployer });
	const GAME_ADMIN = await equip.GAME_ADMIN();
	await equip.grantRole(GAME_ADMIN, accounts[0]);
};