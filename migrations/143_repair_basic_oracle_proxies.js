const { hasNamedProxy, setNamedProxyAddress } = require('./utils/named-proxy');

const BasicPriceOracle = artifacts.require('BasicPriceOracle');
const Blacksmith = artifacts.require('Blacksmith');
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer) {
  const priceOracle = await BasicPriceOracle.deployed();

  if (!hasNamedProxy(priceOracle, 'SkillPriceOracle')) {
    game = await CryptoBlades.deployed();

    const skillPriceOracleAddress = await game.priceOracleSkillPerUsd();

    console.log(`Adding proxy address [${skillPriceOracleAddress}] for SkillPriceOracle`)
    setNamedProxyAddress(priceOracle, 'SkillPriceOracle', skillPriceOracleAddress);
  }

  if (!hasNamedProxy(priceOracle, 'KingPriceOracle')) {
    blacksmith = await Blacksmith.deployed();

    const LINK_KING_ORACLE = await blacksmith.LINK_KING_ORACLE();
    const kingPriceOracleAddress = await blacksmith.getLink(LINK_KING_ORACLE);

    console.log(`Adding proxy address [${kingPriceOracleAddress}] for KingPriceOracle`)
    setNamedProxyAddress(priceOracle, 'KingPriceOracle', kingPriceOracleAddress);
  }
};
