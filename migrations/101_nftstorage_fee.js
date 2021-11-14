const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const NFTStorage = artifacts.require("NFTStorage");

module.exports = async function (deployer, network, accounts) {
   const cryptoBlades = await CryptoBlades.deployed();
   const storage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
   
   storage.migrateTo_56837f7(cryptoBlades.address);
   storage.setBridgeFee(web3.utils.toWei('0.1', 'ether'));
   
   const game_GAME_ADMIN = await cryptoBlades.GAME_ADMIN();
   cryptoBlades.grantRole(game_GAME_ADMIN, storage.address);
};
