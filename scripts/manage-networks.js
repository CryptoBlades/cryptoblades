const shell = require('shelljs');
const _ = require('lodash');
const yargs = require('yargs/yargs');

function backupNetworks(networkId, fileId = null) {
    const savedNetworks = {};

    for(const buildArtifact of shell.ls('build/contracts/*.json')) {
        const data = JSON.parse(shell.cat(buildArtifact));

        savedNetworks[buildArtifact] = data.networks[networkId];
    }

    const jsonFileId = fileId || networkId;
    shell.ShellString(JSON.stringify(savedNetworks, null, '  ')).to(`networks/networks-${jsonFileId}.json`);

    console.log(`Addresses for network ID ${networkId} have been backed up to networks/networks-${jsonFileId}.json.`);
}

function restoreNetworks(networkId, doForce = false, fileId = null) {
    const jsonFileId = fileId || networkId;
    const savedNetworks = JSON.parse(shell.cat(`networks/networks-${jsonFileId}.json`));

    const filesToWrite = [];

    for(const artifactFile in savedNetworks) {
        const catRes = shell.cat(artifactFile);
        if(catRes.code !== 0) {
            console.error(`WARNING: UNABLE TO READ FILE ${artifactFile} - have you made sure it exists?`);
            continue;
        }

        const buildArtifact = JSON.parse(catRes);
        buildArtifact.networks = (buildArtifact.networks || {});

        if(doForce || (
            _.isEqual(buildArtifact.networks[networkId], savedNetworks[artifactFile]) ||
            _.isEqual(buildArtifact.networks[networkId], {}) ||
            buildArtifact.networks[networkId] == null
        )) {
            buildArtifact.networks[networkId] = savedNetworks[artifactFile];
            filesToWrite.push({
                filename: artifactFile,
                contents: JSON.stringify(buildArtifact, null, '  ')
            });
        }
        else {
            console.error(`ERROR: File ${artifactFile} contains data for network ID ${networkId} that differs from backed up data - pass --force to force overwriting any existing data.`);
            console.error(`NOTE: No files were written.`);
            process.exit(1);
        }
    }

    for(const { filename, contents } of filesToWrite) {
        shell.ShellString(contents).to(filename);
    }
    console.log(`Addresses for network ID ${networkId} have been restored from networks/networks-${jsonFileId}.json to the build artifacts.`);
}

yargs(process.argv.slice(2))
    .command('backup <networkId>', 'Backup networks from build artifacts', yargs => {
        yargs.check(argv => Number.isInteger(argv.networkId));
    }, argv => {
        backupNetworks(argv.networkId);
    })
    .command('backupToFile <networkId> <fileId>', 'Backup networks from build artifacts', yargs => {
        yargs.check(argv => Number.isInteger(argv.networkId));
        yargs.check(argv => Number.isInteger(argv.fileId));
    }, argv => {
        backupNetworks(argv.networkId, argv.fileId);
    })
    .command('restore <networkId>', 'Restore networks to build artifacts', yargs => {
        yargs
            .check(argv => Number.isInteger(argv.networkId))
            .option('force', { description: 'Force overwrite existing network data even if it is different' })
            .boolean('force');
    }, argv => {
        restoreNetworks(argv.networkId, argv.force);
    })
    .command('restoreFromFile <networkId> <fileId>', 'Restore networks to build artifacts', yargs => {
        yargs
            .check(argv => Number.isInteger(argv.networkId))
            .option('force', { description: 'Force overwrite existing network data even if it is different' })
            .boolean('force');
        yargs.check(argv => Number.isInteger(argv.fileId));
    }, argv => {
        restoreNetworks(argv.networkId, argv.force, argv.fileId);
    })
    .demandCommand()
    .argv;
