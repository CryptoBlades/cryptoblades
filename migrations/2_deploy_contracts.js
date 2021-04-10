const SkillToken = artifacts.require("SkillToken");
const CryptoBlades = artifacts.require("CryptoBlades");
const StakingRewards = artifacts.require("StakingRewards");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(SkillToken);
  const token = await SkillToken.deployed();

  await deployer.deploy(CryptoBlades, token.address);
  const game = await CryptoBlades.deployed();

  await deployer.deploy(StakingRewards, accounts[0], accounts[0], token.address, token.address);

  await token.transferFrom(token.address, game.address, "500000000000000000000000");
  // This next bit is temporary, we'll handle approvals through the frontend somehow
  await token.approve(game.address, "1000000000000000000000000");
  await game.giveMeSkill("1000000");
  await game.mintCharacter();
};
