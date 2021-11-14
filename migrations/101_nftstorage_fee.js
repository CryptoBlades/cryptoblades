const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const NFTStorage = artifacts.require("NFTStorage");

module.exports = async function (deployer, network, accounts) {
   const cryptoBlades = await CryptoBlades.deployed();
   const storage = await upgradeProxy(NFTStorage.address, NFTStorage, { deployer });
   
   storage.migrateTo_something(cryptoBlades);
   storage.setBridgeFee(web3.utils.toWei('0.1', 'ether'));
};
