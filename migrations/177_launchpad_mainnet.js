const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");

const Launchpad = artifacts.require("Launchpad");
const CryptoBlades = artifacts.require("CryptoBlades");

module.exports = async function (deployer, network, accounts) {
  if (network === 'bscmainnet'
    || network === 'bscmainnet-fork'
    || network === 'hecomainnet'
    || network === 'okexmainnet'
    || network === 'polygonmainnet'
    || network === 'avaxmainnet'
    || network === 'avaxmainnet-fork'
    || network === 'auroramainnet'
    || network === 'skalemainnet' || network === 'coinexmainnet' || network === 'metermainnet'  || network === 'cronosmainnet'
    || network === 'kavamainnet') {
    const game = await CryptoBlades.deployed();
    const launchpad = await deployProxy(Launchpad, [game.address], { deployer });
    const GAME_ADMIN = await game.GAME_ADMIN();
    await game.grantRole(GAME_ADMIN, launchpad.address);

    // VAR_TIERS_AMOUNT = 1;
    // VAR_FUNDING_PERIOD_PHASE_1 = 2;
    // VAR_FUNDING_PERIOD_PHASE_2 = 3;
    // VAR_UNCLAIMED_TO_ALLOCATION_MULTIPLIER = 4;
    // VAR_UNCLAIMED_ALLOCATION_PERCENTAGE = 5;
    // VAR_UNCLAIMED_COMMIT_WINDOW = 6;
    // VAR_UNCLAIMED_COMMIT_START_OFFSET = 7;
    await launchpad.setVars([2,3,4,5,6,7],[7200,3600,1,5,86400,172800]);
    await launchpad.setSkillPrice('2000000000000000000');
  }
};