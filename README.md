# CryptoBlades

## Getting Started

`npm install`

Create a `.env` file in `frontend` with the following values:

- `VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS`
- `VUE_APP_STAKING_REWARDS_CONTRACT_ADDRESS`
- `VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS`

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
- `npm run contract:prepare` - extract the ABI and re-compile Truffle contracts
- `npm run contract:deploy` - deploy the Truffle contracts for testing