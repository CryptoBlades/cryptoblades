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
          providerOrUrl: process.env.BINANCE_TESTNET_RPC_URL || 'https://data-seed-prebsc-1-s1.binance.org:8545/'
        }
      )),
      network_id: 0x61,
      confirmations: 10,
      timeoutBlocks: 200,
      gas: 10000000,//8000000,
      gasPrice: 10000000000,
      skipDryRun: true
    },
    bscmainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.BINANCE_MAINNET_WALLET_PRIVATE_KEY,
        process.env.BINANCE_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.BINANCE_MAINNET_RPC_URL || 'https://bsc-dataseed.binance.org/'
        }
      )),
      gasPrice: 5000000000,
      network_id: 0x38,
      confirmations: 10,
      timeoutBlocks: 200,
      gas: 5600000,
      skipDryRun: true
    },
    hecotestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.HECO_TESTNET_WALLET_PRIVATE_KEY,
        process.env.HECO_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.HECO_TESTNET_RPC_URL || 'wss://ws-testnet.hecochain.com'
        }
      )),
      gasPrice: 1000000000,
      network_id: 0x100,
      confirmations: 10,
      timeoutBlocks: 200,
      gas: 5600000,
      skipDryRun: true
    },
    hecomainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.HECO_MAINNET_WALLET_PRIVATE_KEY,
        process.env.HECO_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.HECO_MAINNET_RPC_URL || 'https://http-mainnet.hecochain.com'
        }
      )),
      network_id: 0x80,
      confirmations: 10,
      timeoutBlocks: 200,
      gas: 5600000,
      skipDryRun: true
    },
    okextestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.OKEX_TESTNET_WALLET_PRIVATE_KEY,
        process.env.OKEX_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.OKEX_TESTNET_RPC_URL || 'https://exchaintestrpc.okex.org',
          pollingInterval: 10000000,
        }
      )),
      gasPrice: 1000000000,
      network_id: 0x41,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    okexmainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.OKEX_MAINNET_WALLET_PRIVATE_KEY,
        process.env.OKEX_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.OKEX_MAINNET_RPC_URL || 'https://exchainrpc.okex.org'
        }
      )),
      gasPrice: 1000000000,
      network_id: 0x42,
      confirmations: 10,
      timeoutBlocks: 200,
      gas: 5600000,
      skipDryRun: true
    },
    polygontestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.POLYGON_TESTNET_WALLET_PRIVATE_KEY,
        process.env.POLYGON_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.POLYGON_TESTNET_RPC_URL || 'wss://ws-matic-mumbai.chainstacklabs.com'
        }
      )),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    polygonmainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.POLYGON_MAINNET_WALLET_PRIVATE_KEY,
        process.env.POLYGON_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.POLYGON_MAINNET_RPC_URL || 'https://polygon-rpc.com/'
        }
      )),
      gasPrice: 100000000000,
      network_id: 137,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    avaxtestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.AVAX_TESTNET_WALLET_PRIVATE_KEY,
        process.env.AVAX_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.AVAX_TESTNET_RPC_URL || 'https://api.avax-test.network/ext/bc/C/rpc'
        }
      )),
      network_id: 43113, // 1 or * for deployment, 43113 for verification (for truffle-plugin-verify to pick up snowtracer api key)
      gas: 6000000,
      gasPrice: 25000000000,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    avaxmainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.AVAX_MAINNET_PRIVATE_KEY,
        process.env.AVAX_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.AVAX_MAINNET_RPC_URL || 'https://api.avax.network/ext/bc/C/rpc'
        }
      )),
      network_id: 43114, // 1 or * for deployment, 43114 for verification (for truffle-plugin-verify to pick up snowtracer api key)
      gas: 7000000,
      gasPrice: 31000000000,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    auroratestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.AURORA_TESTNET_PRIVATE_KEY,
        process.env.AURORA_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.AURORA_TESTNET_RPC_URL || 'wss://testnet.aurora.dev'
        }
      )),
      network_id: 0x4e454153,
      gas: 8000000,
      gasPrice: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    auroramainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.AURORA_MAINNET_PRIVATE_KEY,
        process.env.AURORA_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.AURORA_MAINNET_RPC_URL || 'wss://mainnet.aurora.dev'
        }
      )),
      network_id: 0x4e454152,
      gas: 8000000,
      gasPrice: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    kavatestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.KAVA_TESTNET_PRIVATE_KEY,
        process.env.KAVA_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.KAVA_TESTNET_RPC_URL || 'https://evm.evm-alpha.kava.io'
        }
      )),
      network_id: 2221,
      gas: 8000000,
      gasPrice: 7000000000,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    kavamainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.KAVA_MAINNET_PRIVATE_KEY,
        process.env.KAVA_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.KAVA_MAINNET_RPC_URL || 'https://evm2.kava.io'
        }
      )),
      network_id: 2222,
      gas: 8000000,
      gasPrice: 7000000000,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    skaletestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.SKALE_TESTNET_PRIVATE_KEY,
        process.env.SKALE_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.SKALE_TESTNET_RPC_URL || 'https://staging-v2.skalenodes.com/v1/glamorous-grumium'
        }
      )),
      network_id: 2433657680876851,
      gasPrice: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    skalemainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.SKALE_MAINNET_PRIVATE_KEY,
        process.env.SKALE_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.SKALE_MAINNET_RPC_URL || 'https://mainnet.skalenodes.com/v1/affectionate-immediate-pollux'
        }
      )),
      network_id: 1026062157,
      gasPrice: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    coinextestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.COINEX_TESTNET_PRIVATE_KEY,
        process.env.COINEX_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.COINEX_TESTNET_RPC_URL || 'https://testnet-rpc.coinex.net'
        }
      )),
      network_id: 53,
      gasPrice: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    coinexmainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.COINEX_MAINNET_PRIVATE_KEY,
        process.env.COINEX_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.COINEX_MAINNET_RPC_URL || 'https://rpc.coinex.net'
        }
      )),
      network_id: 52,
      gasPrice: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    metertestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.METER_TESTNET_PRIVATE_KEY,
        process.env.METER_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.METER_TESTNET_RPC_URL || 'https://rpctest.meter.io/'
        }
      )),
      network_id: 83,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    metermainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.METER_MAINNET_PRIVATE_KEY,
        process.env.METER_MAINNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.METER_MAINNET_RPC_URL || 'https://rpc.meter.io'
        }
      )),
      network_id: 82,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    cronostestnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.CRONOS_TESTNET_PRIVATE_KEY,
        process.env.CRONOS_TESTNET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.CRONOS_TESTNET_RPC_URL || 'https://evm-t3.cronos.org/'
        }
      )),
      network_id: 338,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    cronosmainnet: {
      provider: () => new HDWalletProvider(hdWalletProviderOptions(
        process.env.CRONOS_MAINET_PRIVATE_KEY,
        process.env.CRONOS_MAINET_WALLET_MNEMONIC,
        {
          providerOrUrl: process.env.CRONOS_MAINNET_RPC_URL || 'https://cronos-evm.publicnode.com'
        }
      )),
      network_id: 25,
      timeoutBlocks: 200,
      skipDryRun: true
    }
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
    bscscan: process.env.BSCSCAN_API_KEY,
    hecoinfo: process.env.HECOINFO_API_KEY,
    OKLink: process.env.OKLINK_API_KEY,
    polygonscan: process.env.POLYGONSCAN_API_KEY,
    snowtrace: process.env.SNOWTRACE_API_KEY
  },
  // subscribers: {
  //   abisToTs: require('./truffle-subscriber-abis-to-ts.js')
  // }
};
