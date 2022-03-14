const { deployProxy } = require('@openzeppelin/truffle-upgrades');

async function deployNamedProxy(Contract, args, opts, name) {
  const chainId = opts.deployer.network_id;
  const contract = await deployProxy(Contract, args, opts);
  setNamedProxyAddress(contract, name, contract.address);
  return contract;
}

function setNamedProxyAddress(contract, proxyName, proxyAddress) {
  const chainId = contract.constructor.network_id;
  if (contract.constructor._json.networks[chainId].namedProxies === undefined)
      contract.constructor._json.networks[chainId].namedProxies = {}
  contract.constructor._json.networks[chainId].namedProxies[proxyName] = proxyAddress;
}

module.exports = {
  deployNamedProxy: deployNamedProxy,
  setNamedProxyAddress: setNamedProxyAddress
}

