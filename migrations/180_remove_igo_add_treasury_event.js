const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const Treasury = artifacts.require("Treasury");

module.exports = async function (deployer, network) {
	await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
	await upgradeProxy(Treasury.address, Treasury, { deployer });
};