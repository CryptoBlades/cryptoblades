const { deployProxy } = require('@openzeppelin/truffle-upgrades');

async function deployNamedProxy(Contract, args, opts, name) {
  const chainId = opts.deployer.network_id;
  const contract = await deployProxy(Contract, args, opts);

  if (contract.constructor._json.networks[chainId].namedProxies === undefined) {
      contract.constructor._json.networks[chainId].namedProxies = {}
  }
  contract.constructor._json.networks[chainId].namedProxies[name] = contract.address;

  return contract;
}

module.exports = {
  deployNamedProxy: deployNamedProxy
}

