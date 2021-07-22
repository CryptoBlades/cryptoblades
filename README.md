# CryptoBlades

## Currency Setup

1. Install [Ganache](https://www.trufflesuite.com/ganache).
IF YOU ENCOUNTER PERMISSION ERROR:
Disable running anti virus. 
Then reinstall and restart device
Check the anti virus if still enable if yes disable
and run Ganache

1. For Ganache, choose New Workspace.
Fill up the following on each tab:

WORKSPACE 
workspace name  : any

SERVER  
Hostname : any
Port number : default
Network ID : default

ACCOUNTS & KEY 
default all

CHAIN 
Gas Limit : 99999999
Gas Price : default
Hardfork : default


1. Install [MetaMask](https://metamask.io/).
1. In Metamask Add a New Network 
Fill up the following
Network Name : any
New RPC URL : http://localhost:7545
Chain ID : any
Currency Symbol: (optional)
Block Explorer URL: (optional)

1. In Ganache, click the key icon on the right side of any address and grab the private key.
1. In MetaMask, create a new account, import from private key, and paste the key in there.

Then select the New Network you added.

You should now have 100 fake eth! You're now fake rich.

## Frontend Setup

1. `npm install`
1. Create a new file named `.env` in the 'frontend' directory alongside `.env.mainnet` and `.env.testnet` [**Edit this file to include the following lines of code**](https://github.com/CryptoBlades/cryptoblades/blob/main/frontend/.env.testnet#L1-L5)
1. `npm run contract:prepare` (this builds your contracts)
1. `npm run contract:deploy` (this deploys your contracts to your local blockchain)
1. `npm run start:frontend`

For Windows developers experiencing errors follow these steps:
1. `rm -r build`
1. `npm run contract:prepare` (this builds your contracts)
1. `rm -r build/contracts`
1. `npm run contract:deploy`
1. `npm run start:frontend`

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
- If you run into any error at all during the build process you may need to reset [Ganache](https://www.trufflesuite.com/ganache) by deleting previous workspaces and going through the Ganache setup process again including importing a new account for Metamask.
- Artifacts are from different compiler runs `- rm -rf build/`
