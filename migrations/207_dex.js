const {deployProxy} = require("@openzeppelin/truffle-upgrades");

const Dex = artifacts.require("Dex");

module.exports = async function (deployer) {
  const dex = await deployProxy(Dex, [], {deployer});
  const VAR_FEE = await dex.VAR_FEE();
  await dex.setVar(VAR_FEE, 0.3 * 100); // 0.3%
};