const assert = require('assert');
const path = require('path');
const shell = require('shelljs');
const _ = require('lodash');
const TruffleConfig = require('@truffle/config');
const TruffleProvider = require('@truffle/provider');
const Web3 = require('web3');
const yargs = require('yargs/yargs');
const Graph = require('graph-data-structure');

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

async function getProxyImplementation(admin, proxyAddress) {
    try {
        return await admin.methods.getProxyImplementation(proxyAddress).call();
    }
    catch(err) {
        return null;
    }
}

function createInheritanceGraph(buildArtifacts) {
    const g = Graph();

    for(const buildArtifact of buildArtifacts) {
        const { contractName, ast: { nodes } } = JSON.parse(shell.cat(buildArtifact));

        const contractDefNode = nodes.find(node => node.nodeType === 'ContractDefinition');

        assert.ok(contractDefNode);

        g.addNode(contractName);
        for(const baseContract of contractDefNode.baseContracts) {
            g.addEdge(contractName, baseContract.baseName.name);
        }
    }

    return g;
}

function isUpgradeableContract(buildArtifact, inheritanceGraph) {
    const { contractName } = JSON.parse(shell.cat(buildArtifact));

    try {
        inheritanceGraph.shortestPath(contractName, 'Initializable');
        return true;
    }
    catch(err) {
        if(/No path found/ig.test(err.message)) {
            return false;
        }
        else throw err;
    }
}

async function main() {
    shell.pushd(path.join(__dirname, '..'));

    const argv = yargs(process.argv.slice(2))
        .option('network', {
            default: 'development',
            string: true
        })
        .argv;
    const { network } = argv;

    const truffleConfig = TruffleConfig.detect();
    const truffleProvider = TruffleProvider.create(truffleConfig.networks[network]);
    const web3 = new Web3(truffleProvider);

    const chainId = await web3.eth.getChainId();
    const networkId = await web3.eth.net.getId();

    const [ozFile] = shell.ls(`.openzeppelin/*-${chainId}.json`);
    const { admin: { address: adminAddress } } = JSON.parse(shell.cat(ozFile));

    const admin = new web3.eth.Contract(proxyAdminAbi, adminAddress);

    const allBuildArtifacts = Array.from(shell.ls('build/contracts/*.json'));

    const implAddressesEntries = await Promise.all(
        allBuildArtifacts.map(async buildArtifact => {
            const { networks } = JSON.parse(shell.cat(buildArtifact));
            const network = networks[networkId];
            if(network) {
                const { address: proxyAddress } = network;

                return [buildArtifact, await getProxyImplementation(admin, proxyAddress)];
            }
        })
    );

    const implAddresses = Object.fromEntries(implAddressesEntries.filter(Boolean));
    const inheritanceGraph = createInheritanceGraph(allBuildArtifacts);

    const plainContractsToVerify = [];
    const implContractsToVerify = [];

    for (const buildArtifact in implAddresses) {
        const { contractName } = JSON.parse(shell.cat(buildArtifact));
        const implAddress = implAddresses[buildArtifact];

        assert.strictEqual(!!implAddress, isUpgradeableContract(buildArtifact, inheritanceGraph));

        if(implAddress) {
            implContractsToVerify.push(`${contractName}@${implAddress}`);
        }
        else {
            plainContractsToVerify.push(contractName);
        }
    }

    console.log();
    console.log(`Verifying: ${plainContractsToVerify.join(' ')} ${implContractsToVerify.join(' ')}`);
    console.log();

    shell.exec(`npx truffle run verify ${plainContractsToVerify.join(' ')} ${implContractsToVerify.join(' ')} --network ${network}`);

    shell.popd();

    shell.exit(0);
}

main().catch(err => console.error(err));
