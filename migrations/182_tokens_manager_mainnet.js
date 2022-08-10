const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const CryptoBlades = artifacts.require("CryptoBlades");
const TokensManager = artifacts.require("TokensManager");

module.exports = async function (deployer, network, accounts) {
  if (network === 'bscmainnet'
  || network === 'bscmainnet-fork'
  || network === 'hecomainnet'
  || network === 'okexmainnet'
  || network === 'polygonmainnet'
  || network === 'avaxmainnet'
  || network === 'avaxmainnet-fork'
  || network === 'auroramainnet'
  || network === 'skalemainnet'
  || network === 'kavamainnet') {
      const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

      const tokensManager = await deployProxy(
          TokensManager,
          [game.address],
          { deployer }
      );
      await tokensManager.grantRole(await tokensManager.GAME_ADMIN(), accounts[0]);
      await game.grantRole(await game.GAME_ADMIN(), tokensManager.address);

      // $1.74
      let skillTokenPrice = 174;

      if(network === 'bscmainnet' || network === 'bscmainnet-fork') {
        await tokensManager.setTokenPrice(28592);
      }
      else if(network === 'hecomainnet') {
        await tokensManager.setTokenPrice(438);
      }
      else if(network === 'okexmainnet') {
        await tokensManager.setTokenPrice(1814);
      }
      else if(network === 'polygonmainnet') {
        await tokensManager.setTokenPrice(88);
      }
      else if(network === 'avaxmainnet' || network === 'avaxmainnet-fork') {
        await tokensManager.setTokenPrice(2318);
      }
      else if(network === 'auroramainnet') {
        await tokensManager.setTokenPrice(164267);
      }
      else if(network === 'skalemainnet') {
        await tokensManager.setTokenPrice(999999);
        skillTokenPrice = 1;
      }
      else if(network === 'kavamainnet') {
        await tokensManager.setTokenPrice(207);
      }

      await tokensManager.setSkillTokenPrice(skillTokenPrice);
    }
};