const SkillToken = artifacts.require("SkillToken");
const CryptoBlades = artifacts.require("CryptoBlades");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");

module.exports = async function (deployer, network) {
  if (network === 'development' || network === 'development-fork') {
    const token = await SkillToken.deployed();
    const game = await CryptoBlades.deployed();
    await token.transferFrom(token.address, game.address, web3.utils.toWei('0.5', 'mether')); // megaether

    const priceOracle = await BasicPriceOracle.deployed();
    await priceOracle.setCurrentPrice(web3.utils.toWei('0.2', 'ether')); // 1/5 SKILL per USD, AKA 5 USD per SKILL
  }
};
