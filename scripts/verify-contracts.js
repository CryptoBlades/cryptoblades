const assert = require('assert');
const path = require('path');
const shell = require('shelljs');
const _ = require('lodash');
const TruffleConfig = require('@truffle/config');
const TruffleProvider = require('@truffle/provider');
const Web3 = require('web3');
const yargs = require('yargs/yargs');

const proxyAdminAbi = [
    {
        "inputs": [
            {
                "internalType": "contract AdminUpgradeabilityProxy",
                "name": "proxy",
                "type": "address"
            }
        ],
        "name": "getProxyImplementation",
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "owner",
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
];

async function main() {
    shell.pushd(path.join(__dirname, '..'));

    const argv = yargs(process.argv.slice(2))
        .option('network', {
            default: 'development',
            string: true
        })
        .option('known-proxy-contract-name', {
            alias: ['c'],
            default: [],
            array: true
        })
        .option('force-lookup', {
            alias: ['L'],
            default: false,
            boolean: true
        })
        .argv;
    const { network, knownProxyContractName, forceLookup } = argv;

    const truffleConfig = TruffleConfig.detect();
    const truffleProvider = TruffleProvider.create(truffleConfig.networks[network]);
    const web3 = new Web3(truffleProvider);

    const chainId = await web3.eth.getChainId();
    const networkId = await web3.eth.net.getId();

    const [ozFile] = shell.ls(`.openzeppelin/*-${chainId}.json`);
    const { admin: { address: adminAddress }, impls } = JSON.parse(shell.cat(ozFile));

    const admin = new web3.eth.Contract(proxyAdminAbi, adminAddress);

    // console.log(
    //     'the owner of the admin is:',
    //     await admin.methods.owner().call()
    // );

    const txHashToImplAddressMap = {};
    for (const hash in impls) {
        const { address, txHash } = impls[hash];

        assert(!(txHash in txHashToImplAddressMap));

        txHashToImplAddressMap[txHash] = address;
    }

    const contractsToVerify = [];

    for (const buildArtifact of shell.ls('build/contracts/*.json')) {
        const { contractName, networks } = JSON.parse(shell.cat(buildArtifact));

        const network = networks[networkId];
        if (network) {
            const { address: proxyAddress, transactionHash: proxyTransactionHash } = network;
            let implAddress = txHashToImplAddressMap[proxyTransactionHash];

            if ((!implAddress || forceLookup) && proxyAddress && knownProxyContractName.includes(contractName)) {
                implAddress = await admin.methods.getProxyImplementation(proxyAddress).call();
            }

            if(implAddress) {
                contractsToVerify.push(`${contractName}@${implAddress}`);
            }
        }
    }

    console.log();
    console.log('This script intentionally does not actually run the verification. To do that, run this following command manually:');
    console.log();
    console.log(`    npx truffle run verify ${contractsToVerify.join(' ')} --network ${network}`);
    console.log();

    shell.popd();

    shell.exit(0);
}

main().catch(err => console.error(err));
