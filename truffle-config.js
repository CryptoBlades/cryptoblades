/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

require('dotenv').config();

function hdWalletProviderOptions(privateKeyEnvVarValue, mnemonicPhraseEnvVarValue, otherOpts) {
  const opts = { ...otherOpts };
  if(privateKeyEnvVarValue) {
    opts.privateKeys = [privateKeyEnvVarValue];
  }
  else {
    opts.mnemonic = mnemonicPhraseEnvVarValue;
  }
  return opts;
}

const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
    development: {
      host: process.env.ETH_DEV_RPC_HOST || '127.0.0.1',     // Localhost (default: none)
      port: process.env.ETH_DEV_RPC_PORT || 7545,            // Standard Ethereum port (default: none)
      network_id: process.env.ETH_DEV_RPC_NETWORK_ID || '*',       // Any network (default: none)
      gas: parseInt(process.env.ETH_DEV_RPC_GAS, 10) || 67219750 // required for deploy, otherwise it throws weird require-errors on constructor
    },
    bsctestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.BINANCE_WALLET_PRIVATE_KEY,
        process.env.BINANCE_WALLET_MNEMONIC,
        {
          providerOrUrl: 'https://data-seed-prebsc-2-s2.binance.org:8545/'
        }
      )),
      network_id: 0x61,
      confirmations: 10,
      timeoutBlocks: 200,
      gas: 10000000,//8000000,
      skipDryRun: true
    },
    bscmainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.BINANCE_MAINNET_WALLET_PRIVATE_KEY,
        process.env.BINANCE_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: 'https://bsc-dataseed.binance.org/'
        }
      )),
      network_id: 0x38,
      confirmations: 10,
      timeoutBlocks: 200,
      gas: 5600000,
      skipDryRun: true
    },
    // Another network with more advanced options...
    // advanced: {
    // port: 8777,             // Custom port
    // network_id: 1342,       // Custom network
    // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
    // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
    // from: <address>,        // Account to send txs from (default: accounts[0])
    // websocket: true        // Enable EventEmitter interface for web3 (default: false)
    // },
    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    // ropsten: {
    // provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
    // network_id: 3,       // Ropsten's id
    // gas: 5500000,        // Ropsten has a lower block limit than mainnet
    // confirmations: 2,    // # of confs to wait between deployments. (default: 0)
    // timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
    // skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    // },
    // Useful for private networks
    // private: {
    // provider: () => new HDWalletProvider(mnemonic, `https://network.io`),
    // network_id: 2111,   // This network is yours, in the cloud.
    // production: true    // Treats this network as if it was a public net. (default: false)
    // }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.5",    // Fetch exact version from solc-bin (default: truffle's version)
      //docker: false,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
        //evmVersion: "byzantium"
      }
    }
  },
  plugins: [
    "truffle-plugin-verify",
    "truffle-contract-size"
  ],
  api_keys: {
    bscscan: process.env.BSCSCAN_API_KEY
  },
  // subscribers: {
  //   abisToTs: require('./truffle-subscriber-abis-to-ts.js')
  // }
};
