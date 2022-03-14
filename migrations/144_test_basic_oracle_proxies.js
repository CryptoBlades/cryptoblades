const { requireNamedProxy } = require('./utils/named-proxy');

const BasicPriceOracle = artifacts.require('BasicPriceOracle');
const KingPriceOracle = requireNamedProxy('BasicPriceOracle', 'KingPriceOracle');
const SkillPriceOracle = requireNamedProxy('BasicPriceOracle', 'SkillPriceOracle');

module.exports = async function (deployer) {
  const priceOracle = await BasicPriceOracle.deployed();
  console.log(`${priceOracle.address} BasicPriceOracle`);
  console.log((await priceOracle.currentPrice()).toString());
  console.log()

  const skillPriceOracle = await SkillPriceOracle.deployed();
  console.log(`${skillPriceOracle.address} SkillPriceOracle`);
  console.log((await skillPriceOracle.currentPrice()).toString());
  console.log()

  const kingPriceOracle = await KingPriceOracle.deployed();
  console.log(`${kingPriceOracle.address} KingPriceOracle`);
  console.log((await kingPriceOracle.currentPrice()).toString());
  console.log()
};
