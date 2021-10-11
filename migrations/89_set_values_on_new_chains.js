const Blacksmith = artifacts.require("Blacksmith");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");
const Shields = artifacts.require("Shields");

module.exports = async function (deployer, network, accounts) {
  if(network === 'hecomainnet' || network === 'okexmainnet' || network === 'polygonmainnet') {
    const blacksmith = await Blacksmith.deployed();
    const shields = await Shields.deployed();
    const basicPriceOracle = await BasicPriceOracle.deployed();

    const shields_GAME_ADMIN = await shields.GAME_ADMIN();
    await shields.revokeRole(shields_GAME_ADMIN, blacksmith.address);

    // current BSC mainnet value
    await basicPriceOracle.setCurrentPrice('15946519401028800');
  }
};