const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const EquipmentManager = artifacts.require("EquipmentManager");
const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");
const TokensManager = artifacts.require("TokensManager");
const CharactersBridgeProxyContract = artifacts.require("CharactersBridgeProxyContract");
const Raid1 = artifacts.require("Raid1");
const PvpCore = artifacts.require("PvpCore");

module.exports = async function (deployer, network, accounts) {
    await upgradeProxy(EquipmentManager.address, EquipmentManager, { deployer });
    await upgradeProxy(Characters.address, Characters, { deployer });
	await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    await upgradeProxy(Weapons.address, Weapons, { deployer });
	await upgradeProxy(Shields.address, Shields, { deployer });
	await upgradeProxy(TokensManager.address, TokensManager, { deployer });
	await upgradeProxy(CharactersBridgeProxyContract.address, CharactersBridgeProxyContract, { deployer });
	await upgradeProxy(Raid1.address, Raid1, { deployer });
	await upgradeProxy(PvpCore.address, PvpCore, { deployer });
};