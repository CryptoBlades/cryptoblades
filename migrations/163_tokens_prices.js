const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const CryptoBlades = artifacts.require("CryptoBlades");
const TokensPrices = artifacts.require("TokensPrices");

module.exports = async function (deployer, network, accounts) {
    const game = await CryptoBlades.deployed();

    if (
        network === "development" ||
        network === "development-fork" ||
        network === 'bsctestnet' ||
        network === 'bsctestnet-fork' ||
        network === 'hecotestnet' ||
        network === 'okextestnet' ||
        network === 'polygontestnet' ||
        network === 'avaxtestnet' ||
        network === 'avaxtestnet-fork' ||
        network === 'auroratestnet'
        ) 
    {
        const tokensPrices = await deployProxy(
            TokensPrices,
            [],
            { deployer }
        );

        await tokensPrices.grantRole(await tokensPrices.GAME_ADMIN(), accounts[0]);
        await game.setTokensPricesAddress(tokensPrices.address);

        if (network === 'bsctestnet' || network === 'bsctestnet-fork') {
            // TODO: This is the PvP bot's address, do we want this one or another one?
            const tokensPricesBotAddress = '0xC24658012D08a8A575Aa140C7EE45e83c9100F73';
      
            await tokensPrices.grantRole(await tokensPrices.GAME_ADMIN(), tokensPricesBotAddress);
        }
    }
};