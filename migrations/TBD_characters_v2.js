const { upgradeProxy, deployProxy} = require("@openzeppelin/truffle-upgrades");

const Characters = artifacts.require("Characters");
const CryptoBlades = artifacts.require("CryptoBlades");
const Treasury = artifacts.require("Treasury");

module.exports = async function (deployer) {
  await upgradeProxy(Characters.address, Characters, { deployer });
  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });
  await upgradeProxy(Treasury.address, Treasury, { deployer });
  await deployer.deploy(GoldToken);
};