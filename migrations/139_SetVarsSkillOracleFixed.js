const BasicPriceOracle = artifacts.require("BasicPriceOracle");
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network) {
    const game = await CryptoBlades.deployed();
    const priceOracle = await BasicPriceOracle.deployed();

    // BasicPriceOracle points to KING instead of SKILL after migration 92,
    // on local.  I'm not clear why mainnets don't seem to have this issue.
    //
    // The following logic retrieves the SKILL oracle from the game contract
    // and updates the priceOracle variable's addresses.
    const skillPriceOracleAddress = await game.priceOracleSkillPerUsd();
    priceOracle.address = skillPriceOracleAddress;
    priceOracle.contract._address = skillPriceOracleAddress;

    // Find the price reported by the SKILL oracle.
    const currentPrice = await priceOracle.currentPrice();

    // Store the price in vars[VAR_PARAM_ORACLE_FIXED_PRICE].
    const paramOracleFixedPrice = await game.VAR_PARAM_ORACLE_FIXED_PRICE();
    await game.setVar(paramOracleFixedPrice, currentPrice);
};
