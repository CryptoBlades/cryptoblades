const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const { deployNamedProxy } = require('./utils/named-proxy');

const CryptoBlades = artifacts.require("CryptoBlades");
const Blacksmith = artifacts.require("Blacksmith");
const CBKLandSale = artifacts.require("CBKLandSale");
const CBKLand = artifacts.require("CBKLand");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");
const ExperimentToken = artifacts.require("ExperimentToken");

module.exports = async function (deployer, network, accounts) {
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });
  await upgradeProxy(CBKLand.address, CBKLand, { deployer });
  await upgradeProxy(CBKLandSale.address, CBKLandSale, { deployer });

  if (network === 'development' || network === 'development-fork') {
    const skillOracle = await BasicPriceOracle.deployed();
    const LINK_SKILL_ORACLE_2 = await blacksmith.LINK_SKILL_ORACLE_2();
    await blacksmith.setLink(LINK_SKILL_ORACLE_2, skillOracle.address);

    const kingOracle = await deployNamedProxy(BasicPriceOracle, [], { deployer }, 'KingPriceOracle');
    await kingOracle.setCurrentPrice("3333333333333333333"); // about 0.3 usd per king
    const LINK_KING_ORACLE = await blacksmith.LINK_KING_ORACLE();
    await blacksmith.setLink(LINK_KING_ORACLE, kingOracle.address);

    const expToken = await ExperimentToken.deployed();
    await blacksmith.setCurrency(1, expToken.address, true); // attaching EXP token as KING for development

    await blacksmith.setCBKLandPrice(1, 100, 0);
    await blacksmith.setCBKLandPrice(1, 100, 1);
    await blacksmith.setCBKLandPrice(2, 288, 0);
    await blacksmith.setCBKLandPrice(2, 288, 1);
    await blacksmith.setCBKLandPrice(3, 5000, 0);
    await blacksmith.setCBKLandPrice(3, 5000, 1);
  }
};