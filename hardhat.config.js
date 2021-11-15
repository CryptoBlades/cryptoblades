// ###############################################################
// NOTE: Hardat is only used in this project for development
// and testing purposes. Officially this project uses Truffle
// ###############################################################

require('@nomiclabs/hardhat-truffle5');
require('@nomiclabs/hardhat-web3');
require('@openzeppelin/hardhat-upgrades');

const truffleConfig = require('./truffle-config');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: truffleConfig.compilers.solc.version,
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      gas: truffleConfig.networks.development.gas,
      blockGasLimit: 67219750,
      mining:{
        auto: true,
        interval: 5000
      }
    },
  },
  paths: {},
};
