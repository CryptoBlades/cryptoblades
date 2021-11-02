const Blacksmith = artifacts.require("Blacksmith");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");
const Shields = artifacts.require("Shields");
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {
  if(network === 'hecomainnet' || network === 'okexmainnet' || network === 'polygonmainnet') {
    const blacksmith = await Blacksmith.deployed();
    const shields = await Shields.deployed();
    const basicPriceOracle = await BasicPriceOracle.deployed();
    const game = await CryptoBlades.deployed()

    const shields_GAME_ADMIN = await shields.GAME_ADMIN();
    await shields.revokeRole(shields_GAME_ADMIN, blacksmith.address);

    // current BSC mainnet value
    await basicPriceOracle.setCurrentPrice('15946519401028800');
    await game.setCharacterMintValue('3000');
  }
};