# CryptoBlades

## Warning

This code is open, but not open source. It is not licensed, which means you cannot use it freely for your own applications. You cannot "base your code on CryptoBlades", nor use our code for anything. At all. This is not permissible under our license terms (which do not exist).

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
- `npm run test:local` - run tests via hardhat, careful, this is not using migrations but rather fixtures which should be kept up to date (`/test/helpers/prepareContracts.js`)

## Errors

- If you run into any error at all during the build process you may need to reset [Ganache](https://www.trufflesuite.com/ganache) by deleting previous workspaces and going through the Ganache setup process again including importing a new account for Metamask.
- Artifacts are from different compiler runs `- rm -rf build/`

## Running tests locally

To run tests locally simply run

`npm run test:local`

> NOTE: Careful, this is not using migrations but rather fixtures which should be kept up to date (`/test/helpers/prepareContracts.js`)

## Config

- All network config is in app-config.json
- `cd frontend` - navigate to frontend folder
- `npm run setup-app-config` -Initial setup of app-config.json file
- If you want to add a new network: add it's configuration in app-config.json and add update currentTokenPrice getter in EarningsCalculator.

## Alternative development flow with Hardhat

This repository uses Truffle, but if for some reason, you'd prefer using hardhat for development, with an ephemeral local blockchain, you can do so too:

Turn on the Hardhat node:
`npx hardhat node`

Generate Hardhat artifacts:
`npx hardhat compile`

Deploy to the Hardhat node:
`export ETH_DEV_RPC_PORT=8545 && npm run deploy --reset`

Run the frontend pointing to hardhat:
`export VUE_APP_NETWORK_ID=31337 && npm run start:frontend`

If you get any issues during deployment, run:
`truffle compile --all`

## i18n (Internationalization) - Adding strings for translation

- We use [vue-18n](https://kazupon.github.io/vue-i18n/) for internationalization
- Fallback is English, if a string is not added or empty

### Replacing strings in the code

- Replace strings in template with `{{$t('keyName')}}`
- Replace strings in script with `i18n.t('keyName')`
- Pass objects/values with `{{$t('keyName', someValue)}}` and use it in en.json:
  `"keyName": "This is {someValue} !"`
- You can use markdown by using v-html:
  `<p v-html="$t('keyName'})"></p>` with `"keyName": "This is <b>bold</b>"`
- Avoid splitting up strings. If a sentences is split up, it can't be translated in some language properly. ([example](https://github.com/CryptoBlades/cryptoblades/blob/57eb5224f2a2149ccb9f3e5f52bb54eb700dbe53/frontend/src/views/Plaza.vue#L22-L24) and [docu](https://kazupon.github.io/vue-i18n/guide/interpolation.html#basic-usage))

### Adding a new language

- Add a new JSON file to ~/frontend/src/locales/ by copying en.json and renaming it to your language code.
  [Use the 2-Letter ISO code of your language](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
- Language is loaded on startup and added to the language drop-down of the Options page.
- The value for the drop-down is "name" at the root of the json map.


### i18n Manager App

- Adding translations is easier with the use of [i18n-manager](https://www.electronjs.org/apps/i18n-manager)
- Download the app, install it on your device and run it.
- Point it to the folder containing locale files. (frontend/src/locales)
- Add translations, save with ctrl + s, you should be able to see changes immediately after rebuilding

![Alt](https://repobeats.axiom.co/api/embed/7c81697202444d7c5da2bce53af27d4f15e04676.svg "Repobeats analytics image")
