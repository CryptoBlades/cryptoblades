const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Merchandise = artifacts.require("Merchandise");
const SkillToken = artifacts.require("SkillToken");

module.exports = async function (deployer, network, accounts) {
  const merch = await upgradeProxy(Merchandise.address, Merchandise, { deployer });
  const GAME_ADMIN = await merch.GAME_ADMIN();
  await merch.grantRole(GAME_ADMIN, accounts[0]);

  //LINK_SKILL_TOKEN needs to be set manually on mainnets
  if (network === 'development' || network === 'development-fork'
    || network === 'bsctestnet' || network === 'bsctestnet-fork'
    || network === 'hecotestnet'
    || network === 'okextestnet'
    || network === 'polygontestnet') {

    const LINK_SKILL_TOKEN = await merch.LINK_SKILL_TOKEN();
    const VAR_ORDERS_ENABLED = await merch.VAR_ORDERS_ENABLED();
    const skillToken = await SkillToken.deployed();
    await merch.setLink(LINK_SKILL_TOKEN, skillToken.address);
    await merch.setVar(VAR_ORDERS_ENABLED, 1);
  }
  
  const VAR_TRACK_INCOME = await merch.VAR_TRACK_INCOME();
  await merch.setVar(VAR_TRACK_INCOME, 1);
};
