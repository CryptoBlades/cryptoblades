const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const WaxBridge = artifacts.require("WaxBridge");

module.exports = async function (deployer, network, accounts) {
  const waxBridge = await deployProxy(WaxBridge, [], { deployer });

  const WAX_BRIDGE = await waxBridge.WAX_BRIDGE();
  await waxBridge.grantRole(WAX_BRIDGE, accounts[0]);
};
