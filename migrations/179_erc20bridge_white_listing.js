const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const ERC20Bridge = artifacts.require("ERC20Bridge");

module.exports = async function (deployer, network) {
	await upgradeProxy(ERC20Bridge.address, ERC20Bridge, { deployer });
};