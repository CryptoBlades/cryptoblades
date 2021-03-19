const SkillToken = artifacts.require("SkillToken");
const Kryptoknights = artifacts.require("Kryptoknights");

module.exports = function (deployer) {
  deployer.deploy(SkillToken, "Skill", "SKILL", '1000000000000000000000000');
  SkillToken.deployed().then(
    tokenInstance => {
      deployer.deploy(Kryptoknights, tokenInstance.address);
      Kryptoknights.deployed().then(
        gameInstance => {
          tokenInstance.transfer(gameInstance.address, '500000000000000000000000');
        }
      );
    }
  );
};
