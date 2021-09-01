const shell = require('shelljs');
const ohm = require('ohm-js');

const solidityTypeGrammar = ohm.grammar(`
SolidityType {
	Type
    	= Array
        | Primitive

    Array = Type "[" integer? "]"

    Primitive
        = IntType
        | BytesType
        | Bool
        | Address
        | String

    IntType = "u"? "int" digit+
    BytesType = "bytes" digit*
    Bool = "bool"
    Address = "address"
    String = "string"

    integer = digit+
}
`);

const s = solidityTypeGrammar.createSemantics();
s.addOperation('makeOutputTsType', {
    Array(innerType, _lBracket, count, _rBracket) {
        const innerTsType = innerType.makeOutputTsType();
        const mCount = count.makeOutputTsType();
        if(mCount.length === 0) {
            return `${innerTsType}[]`;
        } else {
            return `[${Array(mCount[0]).fill(innerTsType).join(', ')}]`;
        }
    },
    IntType(_u, _int, _digits) {
        return 'string';
    },
    BytesType(_bytes, _digits) {
        return 'string';
    },
    Address(_) {
        return 'string';
    },
    Bool(_) {
        return 'boolean';
    },
    String(_) {
        return 'string';
    },
    integer(_unused) {
        return parseInt(this.sourceString, 10);
    }
});
s.addOperation('makeInputTsType', {
    Array(innerType, _lBracket, count, _rBracket) {
        const innerTsType = innerType.makeOutputTsType();
        const mCount = count.makeOutputTsType();
        if(mCount.length === 0) {
            return `${innerTsType}[]`;
        } else {
            return `[${Array(mCount[0]).fill(innerTsType).join(', ')}]`;
        }
    },
    IntType(_u, _int, _digits) {
        return 'string | number';
    },
    BytesType(_bytes, _digits) {
        return 'string';
    },
    Address(_) {
        return 'string';
    },
    Bool(_) {
        return 'boolean';
    },
    String(_) {
        return 'string';
    },
    integer(_unused) {
        return parseInt(this.sourceString, 10);
    }
});

function transformAbiTypeToOutputTsType(abiType) {
    const m = solidityTypeGrammar.match(abiType);

    if(!m.succeeded()) {
        throw new Error(`Unknown ABI type "${abiType}"`);
    }

    return s(m).makeOutputTsType();
}

function transformAbiTypeToInputTsType(abiType) {
    const m = solidityTypeGrammar.match(abiType);

    if(!m.succeeded()) {
        throw new Error(`Unknown ABI type "${abiType}"`);
    }

    return s(m).makeInputTsType();
}

function generateAbiInterfaceTs(contractName, abi) {
    const generateFunction = fnAbi => {
        const params = fnAbi.inputs
            .map((paramAbi, i) => `${paramAbi.name || 'arg' + i}: ${transformAbiTypeToInputTsType(paramAbi.type)}`)
            .join(', ');
        const returnTypes = fnAbi.outputs
            .map(outputAbi => transformAbiTypeToOutputTsType(outputAbi.type));

        let returnTypesStr;
        if(returnTypes.length === 0) {
            returnTypesStr = 'void';
        } else if(returnTypes.length === 1) {
            returnTypesStr = returnTypes[0];
        } else {
            returnTypesStr = `[${returnTypes.join(', ')}]`;
        }

        return `${fnAbi.name}(${params}): Web3JsAbiCall<${returnTypesStr}>;`;
    };

    const fns = abi
        .filter(fnAbi => fnAbi.type === 'function')
        .map(generateFunction)
        .map(s => '  ' + s)
        .join('\n');

    return `
export interface ${contractName} {
${fns}
}
`;
}

let generationInterfaceOutput = "import { Web3JsAbiCall } from '../abi-common';\n";
const contracts = new Set();

for(const buildArtifact of shell.ls('build/contracts/*.json')) {
    const data = JSON.parse(shell.cat(buildArtifact));

    generationInterfaceOutput += generateAbiInterfaceTs(data.contractName, data.abi);
    contracts.add(buildArtifact);
}

shell.ShellString(generationInterfaceOutput).to('build/abi-interfaces.ts');

console.log(`Generated build/abi-interfaces.ts from ${contracts.size} contracts`);
