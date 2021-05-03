const shell = require('shelljs');

function generateAbiJsonTs(contractName, abi) {
    const abiString = JSON.stringify(abi, null, '  ');
    return `export const ${contractName}: ${abiString} = ${abiString};\n`;
}

let generationOutput = '';

for(const buildArtifact of shell.ls('build/contracts/*.json')) {
    const data = JSON.parse(shell.cat(buildArtifact));

    generationOutput += generateAbiJsonTs(data.contractName, data.abi);
}

shell.ShellString(generationOutput).to(`build/abis.ts`);
