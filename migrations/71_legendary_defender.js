const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Blacksmith = artifacts.require("Blacksmith");
const Shields = artifacts.require("Shields");
const Promos = artifacts.require("Promos");

module.exports = async function (deployer, network, accounts) {
  const promos = await upgradeProxy(Promos.address, Promos, { deployer });
  const shields = await upgradeProxy(Shields.address, Shields, { deployer });
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
};
