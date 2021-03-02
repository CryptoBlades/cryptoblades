const Kryptoknights = artifacts.require("Kryptoknights");

module.exports = function (deployer) {
  deployer.deploy(Kryptoknights);
};
