const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const Shields = artifacts.require("Shields");
const NFTStorage = artifacts.require("NFTStorage");
const Blacksmith = artifacts.require("Blacksmith");

module.exports = async function (deployer, network) {
    const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
    const VAR_PURCHASE_SHIELD_TYPE = await blacksmith.VAR_PURCHASE_SHIELD_TYPE();
    const VAR_PURCHASE_SHIELD_SUPPLY = await blacksmith.VAR_PURCHASE_SHIELD_SUPPLY();
    await blacksmith.setVars([VAR_PURCHASE_SHIELD_TYPE, VAR_PURCHASE_SHIELD_SUPPLY],
        [2, 1000]);
 
    let nftStorage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
    let shields = await upgradeProxy(Shields.address, Shields, { deployer });
	await nftStorage.migrateTo_3f597dc(shields.address);
	
    let GAME_ADMIN = await shields.GAME_ADMIN();
    await shields.grantRole(GAME_ADMIN, nftStorage.address);

	// To be manually called when we are ready
	// await nftStorage.allowToken(shields.address);
};
