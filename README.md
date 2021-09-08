# CryptoBlades

## Currency Setup

1. Install [Ganache](https://www.trufflesuite.com/ganache).
1. For Ganache, choose Quickstart Ethereum.
1. Increase the gas limit in the workspace to `99999999` (or some other high number so you can deploy).
1. Install [MetaMask](https://metamask.io/).
1. Create a new connection to connect to Ganache with these settings: http://localhost:7545, any name, any chain id
1. In Ganache, click the key icon on the right side of any address and grab the private key.
1. In MetaMask, create a new account, import from private key, and paste the key in there. 

You should now have 100 fake eth! You're now fake rich.

## Frontend Setup

1. `npm install`
1. `mv .env.local .env` (copy the example env to your local so it can be used)
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

## Environment Variables

There are optional environment variables, most of which have sensible defaults if copied from `.env.local`:

- `VUE_APP_API_URL` - the API URL to use - defaults to prod (which will throw CORS errors on local)

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

