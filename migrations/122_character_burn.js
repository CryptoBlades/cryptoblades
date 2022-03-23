const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const Characters = artifacts.require("Characters");
const NFTMarket = artifacts.require("NFTMarket");
const Garrison = artifacts.require("Garrison");
const CryptoBlades = artifacts.require("CryptoBlades");
const BurningManager = artifacts.require("BurningManager");

module.exports = async function (deployer, network) {
  if (network === "development"
    || network === "development-fork"
    || network === 'bsctestnet'
    || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet'
    || network === 'avaxtestnet'
    || network === 'avaxtestnet-fork' || network === 'auroratestnet') {
    let nftMarket = await upgradeProxy(NFTMarket.address, NFTMarket, { deployer });
    let characters = await upgradeProxy(Characters.address, Characters, { deployer });
    let garrison = await upgradeProxy(Garrison.address, Garrison, { deployer });
    let game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
    let burningManager = await deployProxy(BurningManager, [characters.address, garrison.address, game.address], { deployer });

    await garrison.migrateTo_d514745(game.address);

    let VAR_ROI_DAYS = await burningManager.VAR_ROI_DAYS();
    let VAR_BURN_POWER_MULTIPLIER = await burningManager.VAR_BURN_POWER_MULTIPLIER();
    await burningManager.setVar(VAR_ROI_DAYS, 33);
    await burningManager.setVar(VAR_BURN_POWER_MULTIPLIER, '1000000000000000000');

    let BURNER_ROLE = await burningManager.BURNER_ROLE();
    await burningManager.grantRole(BURNER_ROLE, nftMarket.address);
    await nftMarket.migrateTo_29635ef(burningManager.address);

    let GAME_ADMIN = await game.GAME_ADMIN();
    await game.grantRole(GAME_ADMIN, burningManager.address);
    await game.grantRole(GAME_ADMIN, garrison.address);

    let characters_GAME_ADMIN = await characters.GAME_ADMIN();
    await characters.grantRole(characters_GAME_ADMIN, burningManager.address);
  }
};
