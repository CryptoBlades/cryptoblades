# CryptoBlades

## Getting Started (Crypto)

1. Install [Ganache](https://www.trufflesuite.com/ganache).

1. For Ganache, choose Quickstart Ethereum.

1. Increase the gas limit in the workspace to `67219751` (or some other high number so you can deploy).

1. Install [MetaMask](https://metamask.io/).

1. Create a new connection to connect to Ganache with these settings: http://localhost:7545, any name, any chain id

1. In Ganache, click the key icon on the right side of any address and grab the private key.

1. In MetaMask, create a new account, import from private key, and paste the key in there. 

You should now have 100 fake eth! You're now fake rich.

## Getting Started (Frontend)

1. `npm install`

1. `npm run contract:deploy` (this deploys your contracts to your local blockchain)

You will also need to create a `.env` file alongside `.env.mainnet` and `.env.testnet`. Inside this file you should only copy the feature flags from either other file. All addresses and other variables are set correctly for local development. **If you don't create a `.env` file, you're going to be missing a lot of the UI.**

But if not specified, the deployed contracts will be pulled in automatically.

### VSCode Setup

If you're using VSCode, we recommend these extensions: Auto Rename Tag, EditorConfig for VSCode, Eslint, Github Pull Requests, Gitlens, Javascript and Typescript, Live Share, Solidity, Typescript Hero, Vetur

## Truffle Environment Variables

Truffle also supports some environment variables, if you create a `.env` file in the root you can specify:

- `ETH_DEV_RPC_HOST`
- `ETH_DEV_RPC_PORT`
- `ETH_DEV_RPC_NETWORK_ID`
- `ETH_DEV_RPC_GAS`
- `BINANCE_WALLET_MNEMONIC`

## Structure

- `contracts` contains the solidity contracts for the game
- `frontend` contains the Vue code for the frontend
- `migrations` contains migration files
- `test` contains tests

## Commands

- `npm run start:frontend` - start up a server for the Vue frontend
- `npm run lint` - run lint checking for all modules
- `npm run contract:prepare` - extract the ABI and re-compile Truffle contracts
- `npm run contract:deploy` - deploy the Truffle contracts for testing

## Errors

- `Artifacts are from different compiler runs` - `rm -rf build/`
