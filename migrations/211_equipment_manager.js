const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const EquipmentManager = artifacts.require("EquipmentManager");
const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");
const TokensManager = artifacts.require("TokensManager");
const CharactersBridgeProxyContract = artifacts.require("CharactersBridgeProxyContract");
const Raid1 = artifacts.require("Raid1");
const PvpCore = artifacts.require("PvpCore");
const BurningManager = artifacts.require("BurningManager");

module.exports = async function (deployer, network, accounts) {
  
    const equip = await deployProxy(EquipmentManager, [], { deployer });
	let EQUIP_GAME_ADMIN = await equip.GAME_ADMIN();
	await equip.grantRole(EQUIP_GAME_ADMIN, accounts[0]);
	let VAR_WEAPON_EQUIP_DURABILITY = await equip.VAR_WEAPON_EQUIP_DURABILITY();
	await equip.setVar(VAR_WEAPON_EQUIP_DURABILITY, 5);
	
	const charactersBridgeProxy = await upgradeProxy(CharactersBridgeProxyContract.address, CharactersBridgeProxyContract, { deployer }); 
	await charactersBridgeProxy.migrate_68c6936(equip.address);

	await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
	await upgradeProxy(TokensManager.address, TokensManager, { deployer });
	
	const raid = await upgradeProxy(Raid1.address, Raid1, { deployer });
	let RAID_LINK_EQUIPMENT_MANAGER = await raid.LINK_EQUIPMENT_MANAGER();
	await raid.registerLink(equip.address, RAID_LINK_EQUIPMENT_MANAGER); //reverse param order vs setLink

    const characters = await upgradeProxy(Characters.address, Characters, { deployer });
	let CHARACTERS_VAR_EQUIPMENT_VERSION = await characters.VAR_EQUIPMENT_VERSION();
	await characters.setVar(CHARACTERS_VAR_EQUIPMENT_VERSION, 1);
	let LINK_CHARACTERS = await equip.LINK_CHARACTERS();
	await equip.setLink(LINK_CHARACTERS, characters.address);
	let CHARACTERS_GAME_ADMIN = await characters.GAME_ADMIN();
	await characters.grantRole(CHARACTERS_GAME_ADMIN, equip.address);

    const weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
	let LINK_WEAPONS = await equip.LINK_WEAPONS();
	await equip.setLink(LINK_WEAPONS, weapons.address);
	let WEAPONS_GAME_ADMIN = await weapons.GAME_ADMIN();
	await weapons.grantRole(WEAPONS_GAME_ADMIN, equip.address);

	const shields = await upgradeProxy(Shields.address, Shields, { deployer });
	let LINK_SHIELDS = await equip.LINK_SHIELDS();
	await equip.setLink(LINK_SHIELDS, shields.address);

    const pvpCore = await upgradeProxy(PvpCore.address, PvpCore, { deployer });
	let PVP_LINK_EQUIPMENT_MANAGER = await pvpCore.LINK_EQUIPMENT_MANAGER();
	await pvpCore.setLink(PVP_LINK_EQUIPMENT_MANAGER, equip.address);

	const burnManager = await upgradeProxy(BurningManager.address, BurningManager, { deployer });
	let BM_LINK_EQUIPMENT_MANAGER = await burnManager.LINK_EQUIPMENT_MANAGER();
	await burnManager.setLink(BM_LINK_EQUIPMENT_MANAGER, equip.address);

	let SLOT_CHARACTER_WEAPON = await equip.SLOT_CHARACTER_WEAPON();
	await equip.setEquippable(characters.address, SLOT_CHARACTER_WEAPON, weapons.address, true);
	let SLOT_CHARACTER_SHIELD = await equip.SLOT_CHARACTER_SHIELD();
	await equip.setEquippable(characters.address, SLOT_CHARACTER_SHIELD, shields.address, true);
};