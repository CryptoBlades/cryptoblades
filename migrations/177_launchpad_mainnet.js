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
    || network === 'auroramainnet') {
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

    let commitOnly = true;
    if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
      commitOnly = false;
    }

    await launchpad.addNewLaunch("Bolstyr", "BOL", "https://cloudflare-ipfs.com/ipfs/QmTBcU7U1hWtGSSjPnAQqF93bYH8c1itvBs8CRoYXYpCWH", "https://cloudflare-ipfs.com/ipfs/QmZDHWx1GHEkeisPhR9FktYEB8ka8QxUvkXyP1URxEC588", "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7", commitOnly)
    await launchpad.addNewLaunch("Magic Connect", "MSHARD", "https://cloudflare-ipfs.com/ipfs/QmTsUCRaLssuDxfK4ENkvCzKk1UJGJH9ouGFsd7YHi5PE1", "https://cloudflare-ipfs.com/ipfs/QmQGfym9oLB3ETTcQCTB6RnLMk7i11wXZZfHPvyf9e9umW", "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7", commitOnly)
    await launchpad.addNewLaunch("Boom Brigade", "MEDAL", "https://cloudflare-ipfs.com/ipfs/QmPTJ7ugmRaexuQ7tUq7KYF6vvwq3Y3rcjxdwZYtZ68ZeG", "https://cloudflare-ipfs.com/ipfs/QmUFMh18omfxPXmz18UBGDZo6wmiKofaH2pjvCKyc8DQJe", "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7", commitOnly)
  }
};