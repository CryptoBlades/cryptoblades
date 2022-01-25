const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const Shields = artifacts.require("Shields");
const NFTStorage = artifacts.require("NFTStorage");

module.exports = async function (deployer, network) {
 
    let nftStorage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
    let shields = await upgradeProxy(Shields.address, Shields, { deployer });
	nftStorage.migratetoSomething(nftStorage.address);
	
    let GAME_ADMIN = await shields.GAME_ADMIN();
    await shields.grantRole(GAME_ADMIN, nftStorage.address);

	nftStorage.allowToken(shields.address);
};
