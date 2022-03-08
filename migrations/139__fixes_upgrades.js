const {upgradeProxy} = require("@openzeppelin/truffle-upgrades");

const SimpleQuests = artifacts.require("SimpleQuests");
const Characters = artifacts.require("Characters");
const CryptoBlades = artifacts.require("CryptoBlades");
const Shields = artifacts.require("Shields");

module.exports = async function (deployer) {
  await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
  await upgradeProxy(Characters.address, Characters, {deployer});
  await upgradeProxy(CryptoBlades.address, CryptoBlades, {deployer});
  await upgradeProxy(Shields.address, Shields, {deployer});
};
