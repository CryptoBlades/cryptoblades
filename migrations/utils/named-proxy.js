const { deployProxy } = require('@openzeppelin/truffle-upgrades');

async function deployNamedProxy(Contract, args, opts, name) {
  const chainId = opts.deployer.network_id;
  const contract = await deployProxy(Contract, args, opts);
  setNamedProxyAddress(contract, name, contract.address);
  return contract;
}

function hasNamedProxy(contract, proxyName) {
  const chainId = contract.constructor.network_id;
  if (contract.constructor._json.networks[chainId].namedProxies === undefined)
    return false;
  return (proxyName in contract.constructor._json.networks[chainId].namedProxies)
}

function requireNamedProxy(ImplementationClassName, proxyName) {
  const implementationClass = artifacts.require(ImplementationClassName);

  implementationClass.deployedDefault = implementationClass.deployed;
  implementationClass.deployed = async function() {
    const proxyContract = await implementationClass.deployedDefault();

    const chainId = implementationClass.network_id;
    proxyAddress = proxyContract.constructor._json.networks[chainId].namedProxies[proxyName]
    proxyContract.address = proxyAddress;
    proxyContract.contract._address = proxyAddress;

    return proxyContract;
  };

  return implementationClass;
}

function setNamedProxyAddress(contract, proxyName, proxyAddress) {
  const chainId = contract.constructor.network_id;
  if (contract.constructor._json.networks[chainId].namedProxies === undefined)
      contract.constructor._json.networks[chainId].namedProxies = {}
  contract.constructor._json.networks[chainId].namedProxies[proxyName] = proxyAddress;
}

module.exports = {
  deployNamedProxy: deployNamedProxy,
  hasNamedProxy: hasNamedProxy,
  requireNamedProxy: requireNamedProxy,
  setNamedProxyAddress: setNamedProxyAddress
}
