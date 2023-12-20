const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const KingERC20BridgeProxyContract = artifacts.require("KingERC20BridgeProxyContract");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer, network) {
  
    let promos = await Promos.deployed();
    await deployProxy(KingERC20BridgeProxyContract, [promos.address], { deployer });
};