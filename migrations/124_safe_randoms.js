const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SafeRandoms = artifacts.require("SafeRandoms");
const Weapons = artifacts.require("Weapons");

module.exports = async function (deployer, network, accounts) {
  const safeRandoms = await deployProxy(SafeRandoms, [], { deployer });
  const GAME_ADMIN = await safeRandoms.GAME_ADMIN();
  await safeRandoms.grantRole(GAME_ADMIN, accounts[0]);

  const weps = await upgradeProxy(Weapons.address, Weapons, { deployer });
};
