const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const Shields = artifacts.require("Shields");

module.exports = async function (deployer, network, accounts) {
  const shields = await deployProxy(Shields, [], { deployer });
  
  const blacksmith = await Blacksmith.deployed();
  await blacksmith.migrateTo_TBD(shields.address);
  const shields_GAME_ADMIN = await shields.GAME_ADMIN();
  await shields.grantRole(shields_GAME_ADMIN, blacksmith.address);
};
