const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const Characters = artifacts.require("Characters");

module.exports = async function (deployer) {
  await upgradeProxy(Characters.address, Characters, { deployer });
};