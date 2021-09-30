
const shell = require('shelljs');
const path = require('path');
const yargs = require('yargs/yargs');
const TruffleConfig = require('@truffle/config');
const TruffleProvider = require('@truffle/provider');
const Web3 = require('web3');
const { merge } = require('sol-merger');
const fs = require('fs');
const axios = require('axios');

async function main() {
  shell.pushd(path.join(__dirname, '..'));
  const mergeDir = 'build/merged-contracts';

  const argv = yargs(process.argv.slice(2))
      .option('network', {
          default: 'development',
          string: true
      })
      .argv;
  const { network } = argv;
  console.log(network);

  const truffleConfig = TruffleConfig.detect();
  const truffleProvider = TruffleProvider.create(truffleConfig.networks[network]);
  const web3 = new Web3(truffleProvider);

  const networkId = await web3.eth.net.getId();
  console.log(networkId);

  const networks = JSON.parse(shell.cat(`networks/networks-${networkId}.json`));
  const contracts = Array.from(shell.ls('contracts/*.sol'));
  const itemsContracts = Array.from(shell.ls('contracts/items/*.sol'));
  const stakingContracts = Array.from(shell.ls('contracts/staking/*.sol'));
  const allContracts = contracts.concat(itemsContracts).concat(stakingContracts);
  const contractsToVerify = [];
  const contractAddresses = [];

  for(let key in networks) {
    const contract = allContracts.find(contract => path.parse(contract).name.toLowerCase() === path.parse(key).name.toLowerCase());
    if(!contract) continue;
    contractsToVerify.push(contract);
    contractAddresses.push(networks[key].address);
  }

  for(let i = 0; i < contractsToVerify.length; i++) {
    const mergedCode = await merge(contractsToVerify[i]);
    if (!fs.existsSync(mergeDir)){
      fs.mkdirSync(mergeDir);
    }
    // fs.writeFile(`build/merged-contracts/${path.parse(contractsToVerify[i]).name}.sol`, mergedCode, function (err) {
    //   if (err) throw err;
    //   console.log(`Merged ${contractsToVerify[i]}`);
    // });

    console.log(`Verifying ${path.parse(contractsToVerify[i]).name}@${contractAddresses[i]}`)
    console.log(JSON.stringify({address: contractAddresses[i],
      contractSource: escape(mergedCode),
      compilerVersion: "v0.6.5+commit.f956cc89",
      compilerType: "Solidity(SingleFile)",
      evmVersion: "default",
      optimization: true,
      optimizationRuns: 200,
      licenseType: "No License (None)",
      contractAbi: ""}));

    axios.post('https://www.oklink.com/api/explorer/v1/okexchain_test/contract/verify', {
      address: contractAddresses[i],
      contractSource: escape(mergedCode),
      compilerVersion: "v0.6.5+commit.f956cc89",
      compilerType: "Solidity(SingleFile)",
      evmVersion: "default",
      optimization: true,
      optimizationRuns: 200,
      licenseType: "No License (None)",
      contractAbi: ""
    })
    .then(res => {
      console.log(`Response ${res}`);
      if(res.data.isSuccess === 'true') {
        console.log(`Verified ${contractsToVerify[i]}`);
      }
    })
    .catch(error => {
      console.log(`Failed to verify ${contractsToVerify[i]}`);
      console.error(error);
    })
  }
}

main().catch(err => console.error(err));