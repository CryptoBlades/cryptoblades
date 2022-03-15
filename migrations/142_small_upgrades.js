const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require('SimpleQuests');
const Garrison = artifacts.require('Garrison');
const Shields = artifacts.require('Shields');
const PvpArena = artifacts.require('PvpArena');
const CryptoBlades = artifacts.require('CryptoBlades');

module.exports = async function (deployer, network) {
  await upgradeProxy(SimpleQuests.address, SimpleQuests, { deployer });
  await upgradeProxy(Garrison.address, Garrison, { deployer });
  await upgradeProxy(Shields.address, Shields, { deployer });
  await upgradeProxy(PvpArena.address, PvpArena, { deployer });
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
};
