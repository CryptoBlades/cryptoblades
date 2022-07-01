const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const ERC20Bridge = artifacts.require("ERC20Bridge");
const SkillERC20BridgeProxyContract = artifacts.require("SkillERC20BridgeProxyContract");
const CryptoBlades = artifacts.require("CryptoBlades");
const SkillToken = artifacts.require("SkillToken");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer, network) {
  
    let promos = await Promos.deployed();
	let cryptoBlades = await CryptoBlades.deployed();
    let erc20Bridge = await deployProxy(ERC20Bridge, [cryptoBlades.address], { deployer });
    let skillProxy = await deployProxy(SkillERC20BridgeProxyContract, [promos.address], { deployer });
    let skillToken = await SkillToken.deployed();
	
    await erc20Bridge.setProxyContract(skillToken.address, skillProxy.address, true);
	
	const game_GAME_ADMIN = await cryptoBlades.GAME_ADMIN();
	await cryptoBlades.grantRole(game_GAME_ADMIN, erc20Bridge.address);
};