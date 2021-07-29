const util = require('util');
const fs = require('fs');

const SkillToken = artifacts.require("SkillToken");
const ExperimentToken = artifacts.require("ExperimentToken");
const ExperimentToken2 = artifacts.require("ExperimentToken2");

writeFileAsync = util.promisify(fs.writeFile);

module.exports = async function (deployer, network, accounts) {
  if (network === 'development' || network === 'development-fork' || network === 'bsctestnet' || network === 'bsctestnet-fork') {
    // tokens
    await deployer.deploy(SkillToken);
    const token = await SkillToken.deployed();

    await deployer.deploy(ExperimentToken);
    const expToken = await ExperimentToken.deployed();

    await deployer.deploy(ExperimentToken2);
    const expToken2 = await ExperimentToken2.deployed();

    // token setup for local dev
    await token.transferFrom(token.address, accounts[0], web3.utils.toWei('1', 'kether')); // 1000 skill, test token value is $5 usd
    await expToken.transferFrom(expToken.address, accounts[0], web3.utils.toWei('599', 'ether'));
    await expToken2.transferFrom(expToken2.address, accounts[0], web3.utils.toWei('699', 'ether'));
  }
};