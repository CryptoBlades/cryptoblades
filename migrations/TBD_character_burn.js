const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const Characters = artifacts.require("Characters");
const NFTMarket = artifacts.require("NFTMarket");
const Garrison = artifacts.require("Garrison");
const CryptoBlades = artifacts.require("CryptoBlades");
const BurningManager = artifacts.require("BurningManager");

module.exports = async function (deployer, network) {
  let nftMarket = await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
  let characters = await upgradeProxy(Characters.address, Characters, { deployer });
  let garrison = await upgradeProxy(Garrison.address, Garrison, { deployer });
  let game = await CryptoBlades.deployed();
  let burningManager = await deployProxy(BurningManager, [characters.address, garrison.address, game.address, '120000000000000000'], { deployer });

  let BURNER_ROLE = await burningManager.BURNER_ROLE();
  await burningManager.grantRole(BURNER_ROLE, nftMarket.address);
  await nftMarket.migrateTo_29635ef(burningManager.address);

  let GAME_ADMIN = await game.GAME_ADMIN();
  await game.grantRole(GAME_ADMIN, burningManager.address);

  let characters_GAME_ADMIN = await characters.GAME_ADMIN();
  await characters.grantRole(characters_GAME_ADMIN, burningManager.address);
};