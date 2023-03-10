const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require('SimpleQuests');

module.exports = async function (deployer, network) {
  if (network === "development"
  || network === "development-fork"
  || network === 'bsctestnet'
  || network === 'bsctestnet-fork'
  || network === 'hecotestnet'
  || network === 'okextestnet'
  || network === 'polygontestnet'
  || network === 'avaxtestnet'
  || network === 'avaxtestnet-fork'
  || network === 'auroratestnet'
  || network === 'kavatestnet'
  || network === 'skaletestnet' || network === 'coinextestnet' || network === 'metertestnet' || network === 'cronostestnet') {
    const simpleQuests = await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
  }
};
