const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const EquipmentManager = artifacts.require("EquipmentManager");
const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");

module.exports = async function (deployer, network, accounts) {
  
    let equip = await deployProxy(EquipmentManager, [], { deployer });
	const GAME_ADMIN = await equip.GAME_ADMIN();
	await equip.grantRole(GAME_ADMIN, accounts[0]);

	await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

    const characters = await upgradeProxy(Characters.address, Characters, { deployer });
	let CHARACTERS_VAR_EQUIPMENT_VERSION = await characters.VAR_EQUIPMENT_VERSION();
	await characters.setVar(CHARACTERS_VAR_EQUIPMENT_VERSION, 1);
	let LINK_CHARACTERS = await equip.LINK_CHARACTERS();
	await equip.setLink(LINK_CHARACTERS, characters.address);

    const weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
	let WEAPONS_VAR_EQUIPMENT_VERSION = await weapons.VAR_EQUIPMENT_VERSION();
	await weapons.setVar(WEAPONS_VAR_EQUIPMENT_VERSION, 1);
	let LINK_WEAPONS = await equip.LINK_WEAPONS();
	await equip.setLink(LINK_WEAPONS, weapons.address);

	const shields = await upgradeProxy(Shields.address, Shields, { deployer });
	let SHIELDS_VAR_EQUIPMENT_VERSION = await shields.VAR_EQUIPMENT_VERSION();
	await shields.setVar(SHIELDS_VAR_EQUIPMENT_VERSION, 1);
	let LINK_SHIELDS = await equip.LINK_SHIELDS();
	await equip.setLink(LINK_SHIELDS, shields.address);
};