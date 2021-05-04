const shell = require('shelljs');

const savedNetworks = {};

for(const buildArtifact of shell.ls('build/contracts/*.json')) {
    const data = JSON.parse(shell.cat(buildArtifact));

    savedNetworks[buildArtifact] = data.networks;
}

const timestamp = Date.now();
shell.ShellString(JSON.stringify(savedNetworks, null, '  ')).to(`build/networks-backup-${timestamp}.json`);
shell.mv('build/contracts', `build/contracts-backup-${timestamp}`);

shell.exec('npx truffle compile --all');

for(const buildArtifact of shell.ls('build/contracts/*.json')) {
    const data = JSON.parse(shell.cat(buildArtifact));

    if (buildArtifact in savedNetworks) {
        data.networks = savedNetworks[buildArtifact];

        shell.ShellString(JSON.stringify(data, null, '  ')).to(buildArtifact);
    }
}

const path = require('path');
shell.exec(`node ${path.join(__dirname, 'generate-ts-from-abis.js')}`);
