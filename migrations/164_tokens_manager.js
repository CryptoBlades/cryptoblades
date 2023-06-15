const { upgradeProxy, deployProxy } = require("@openzeppelin/truffle-upgrades");
const CryptoBlades = artifacts.require("CryptoBlades");
const TokensManager = artifacts.require("TokensManager");

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
    || network === 'skaletestnet' || network === 'coinextestnet' || network === 'metertestnet' || network === 'cronostestnet' || network === 'opsidetestnet') {
        const game = await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

        const tokensManager = await deployProxy(
            TokensManager,
            [game.address],
            { deployer }
        );

        await tokensManager.grantRole(await tokensManager.GAME_ADMIN(), accounts[0]);

        if (network === 'bsctestnet' || network === 'bsctestnet-fork') {
            // TODO: This is the PvP bot's address, do we want this one or another one?
            const tokensManagerBotAddress = '0xC24658012D08a8A575Aa140C7EE45e83c9100F73';
      
            await tokensManager.grantRole(await tokensManager.GAME_ADMIN(), tokensManagerBotAddress);
        }

        await game.grantRole(await game.GAME_ADMIN(), tokensManager.address);
    }
};