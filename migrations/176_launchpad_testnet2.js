const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const Launchpad = artifacts.require("Launchpad");
const CryptoBlades = artifacts.require("CryptoBlades");
const SkillToken = artifacts.require("SkillToken");

module.exports = async function (deployer, network, accounts) {
  if (network === "development"
  || network === "development-fork"
  || network === 'bsctestnet'
  || network === 'bsctestnet-fork'
  || network === 'hecotestnet'
  || network === 'okextestnet'
  || network === 'polygontestnet'
  || network === 'avaxtestnet'
  || network === 'avaxtestnet-fork'
  || network === 'auroratestnet'
  || network === 'kavatestnet'
  || network === 'skaletestnet' || network === 'coinextestnet' || network === 'metertestnet') {
    const game = await CryptoBlades.deployed();
    const launchpad = await deployProxy(Launchpad, [game.address], { deployer });
    const GAME_ADMIN = await game.GAME_ADMIN();
    await game.grantRole(GAME_ADMIN, launchpad.address);
    await launchpad.setBrandNewTiers(
      [1,2,3,4,5,6,7,8], 
      [
        '1000000000000000000',
        '2000000000000000000',
        '5000000000000000000',
        '10000000000000000000',
        '20000000000000000000',
        '30000000000000000000',
        '40000000000000000000',
        '50000000000000000000'
      ],
      [1,2,3,4,5,6,7,8]
    );
    await launchpad.setVars([2,3,4,5,6,7],[1800,1800,1,30,1800,3600]);
    await launchpad.setSkillPrice('4000000000000000000');
  }
};