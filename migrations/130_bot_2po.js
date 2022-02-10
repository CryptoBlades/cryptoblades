const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const NFTStorage = artifacts.require("NFTStorage");
const WeaponBridgeProxyContract = artifacts.require("WeaponBridgeProxyContract");
const CharactersBridgeProxyContract = artifacts.require("CharactersBridgeProxyContract");
const ShieldBridgeProxyContract = artifacts.require("ShieldBridgeProxyContract");
const Weapons = artifacts.require("Weapons");
const Characters = artifacts.require("Characters");
const Shields = artifacts.require("Shields");
const CharacterCosmetics = artifacts.require("CharacterCosmetics");
const CharacterRenameTagConsumables = artifacts.require("CharacterRenameTagConsumables");
const WeaponCosmetics = artifacts.require("WeaponCosmetics");
const WeaponRenameTagConsumables = artifacts.require("WeaponRenameTagConsumables");

module.exports = async function (deployer, network) {
    let storage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
	
	let weapons = await Weapons.deployed();
	let weaponCosmetics = await WeaponCosmetics.deployed();
	let weaponRenameTagConsumables = await WeaponRenameTagConsumables.deployed();
	
	let characters = await Characters.deployed();
	let characterCosmetics = await CharacterCosmetics.deployed();
	let characterRenameTagConsumables = await CharacterRenameTagConsumables.deployed();
	
	let shields = await Shields.deployed();
	
    let weaponProxy = await deployProxy(WeaponBridgeProxyContract, [storage.address, weapons.address, weaponCosmetics.address, weaponRenameTagConsumables.address], { deployer });
	let characterProxy = await deployProxy(CharactersBridgeProxyContract, [storage.address, characters.address, characterCosmetics.address, characterRenameTagConsumables.address], { deployer });
	let shieldProxy = await deployProxy(ShieldBridgeProxyContract, [storage.address, shields.address], { deployer });
	
	await storage.SetProxyContract(weapons.address, weaponProxy.address, true);
	await storage.SetProxyContract(characters.address, characterProxy.address, true);
	await storage.SetProxyContract(shields.address, shieldProxy.address, true);
	
	let weaponsGM = await weapons.MINTER_ROLE(); // Not typo; intended
	let charactersGM = await characters.MINTER_ROLE(); // Not typo; intended
	let shieldsGM = await shields.GAME_ADMIN();
	
	let weaponsProxyGM = await weaponProxy.GAME_ADMIN();
	let charactersProxyGM = await characterProxy.GAME_ADMIN();
	let shieldsProxyGM = await shieldProxy.GAME_ADMIN();
	
	let characterCosmeticsGM = await characterCosmetics.GAME_ADMIN();
	let characterRenameTagConsumablesGM = await characterRenameTagConsumables.GAME_ADMIN();
	
	let weaponCosmeticsGM = await weaponCosmetics.GAME_ADMIN();
	let weaponRenameTagConsumablesGM = await weaponRenameTagConsumables.GAME_ADMIN();
	
	await weapons.grantRole(weaponsGM, weaponProxy.address);
	await characters.grantRole(charactersGM, characterProxy.address);
	await shields.grantRole(shieldsGM, shieldProxy.address);
	
	await weaponProxy.grantRole(weaponsProxyGM, storage.address);
	await characterProxy.grantRole(charactersProxyGM, storage.address);
	await shieldProxy.grantRole(shieldsProxyGM, storage.address);
	
	await weaponCosmetics.grantRole(weaponCosmeticsGM, weaponProxy.address);
	await weaponRenameTagConsumables.grantRole(weaponRenameTagConsumablesGM, weaponProxy.address);
	
	await characterCosmetics.grantRole(characterCosmeticsGM, characterProxy.address);
	await characterRenameTagConsumables.grantRole(characterRenameTagConsumablesGM, characterProxy.address);
	
	
	// Still need to call setChainSupportedForNFT manually
	// Ex: await storage.setChainSupportedForNFT(weapons.address, [56, 128], true); => enables weapons for those two chain
};