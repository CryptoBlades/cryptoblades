const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const NFTStorage = artifacts.require("NFTStorage");
module.exports = async function (deployer, network, accounts) {
   const storage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });

	if (network === 'development' || network === 'development-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork' || network === 'bscmainnet' || network === 'bscmainnet-fork') {
		await storage.setLocalChainPrefix('BSC');
	}
	else if (network === 'hecotestnet' || network === 'hecomainnet') {
		await storage.setLocalChainPrefix('HECO');
	}
	else if (network === 'okextestnet' || network === 'okexmainnet') {
		await storage.setLocalChainPrefix('OKEX');
	}
	else if (network === 'polygontestnet' || network === 'polygonmainnet') {
		await storage.setLocalChainPrefix('POLYGON');
	}
	else if (network === 'avaxtestnet' || network === 'avaxtestnet-fork' || network === 'auroratestnet' || network === 'avaxmainnet' || network === 'auroramainnet') {
		await storage.setLocalChainPrefix('AVAX');
	}
	else {
		throw 'cant find prefix to set'; // we can't have the prefix empty; break the migration
	}
};