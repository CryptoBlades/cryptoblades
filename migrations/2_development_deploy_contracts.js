const SkillToken = artifacts.require("SkillToken");
const ExperimentToken = artifacts.require("ExperimentToken");
const CryptoBlades = artifacts.require("CryptoBlades");
const SkillStakingRewards = artifacts.require("SkillStakingRewards");
const LPStakingRewards = artifacts.require("LPStakingRewards");

module.exports = async function (deployer, network, accounts) {
  if (network === 'development' || network === 'development-fork') {
    await deployer.deploy(SkillToken);
    const token = await SkillToken.deployed();

    await deployer.deploy(ExperimentToken);
    const expToken = await ExperimentToken.deployed();

    await deployer.deploy(CryptoBlades, token.address);
    const game = await CryptoBlades.deployed();

    await deployer.deploy(SkillStakingRewards, accounts[0], accounts[0], token.address, token.address, 60);
    await deployer.deploy(LPStakingRewards, accounts[0], accounts[0], token.address, expToken.address, 0);

    await token.transferFrom(token.address, game.address, "500000000000000000000000");
    // This next bit is temporary, we'll handle approvals through the frontend somehow
    await token.approve(game.address, "1000000000000000000000000");
    await game.giveMeSkill("1000000000000000000000"); // 1000 skill, test token value is $5 usd
    await game.mintCharacter();

    //console.log("Weapon mint gastimate: "+(await game.mintWeapon.estimateGas({ from: accounts[0] })).toString());
  }
};
