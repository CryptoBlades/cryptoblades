const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SafeRandoms = artifacts.require("SafeRandoms");

module.exports = async function (deployer, network, accounts) {
  const safeRandoms = await deployProxy(SafeRandoms, [], { deployer });
  const SEED_AUTHORITY = await safeRandoms.SEED_AUTHORITY();
  await safeRandoms.grantRole(SEED_AUTHORITY, accounts[0]);
};
