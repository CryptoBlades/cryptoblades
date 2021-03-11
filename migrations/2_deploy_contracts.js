const Kryptoknights = artifacts.require("Kryptoknights");
const Weapons = artifacts.require("Weapons");
const Characters = artifacts.require("Characters");

module.exports = function (deployer) {
  //deployer.deploy(Weapons);
  deployer.deploy(Kryptoknights).then(function() {
    deployer.deploy(Weapons, Kryptoknights.address);
    deployer.link(Weapons, Kryptoknights);
    return;
  }).then(function() {
    deployer.deploy(Characters, Kryptoknights.address);
    deployer.link(Characters, Kryptoknights);
    return;
  });
};
