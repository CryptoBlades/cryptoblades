const { deployProxy, prepareUpgrade } = require('@openzeppelin/truffle-upgrades');
const util = require('util');
const path = require('path');
const fs = require('fs');

const SkillToken = artifacts.require("SkillToken");
const ExperimentToken = artifacts.require("ExperimentToken");
const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const SkillStakingRewards = artifacts.require("SkillStakingRewards");
const LPStakingRewards = artifacts.require("LPStakingRewards");
const RaidBasic = artifacts.require("RaidBasic");

writeFileAsync = util.promisify(fs.writeFile);

module.exports = async function (deployer, network, accounts) {
  if (network === 'development' || network === 'development-fork') {
    await deployer.deploy(SkillToken);
    const token = await SkillToken.deployed();

    await deployer.deploy(ExperimentToken);
    const expToken = await ExperimentToken.deployed();

    const charas = await deployProxy(Characters, [], { deployer });
    const weps = await deployProxy(Weapons, [], { deployer });
    const game = await deployProxy(CryptoBlades, [token.address, charas.address, weps.address], { deployer });
    await charas.setMain(game.address);
    await weps.setMain(game.address);

    // TODO make these upgrade-friendly
    await deployer.deploy(SkillStakingRewards, accounts[0], accounts[0], token.address, token.address, 60);
    await deployer.deploy(LPStakingRewards, accounts[0], accounts[0], token.address, expToken.address, 0);

    await deployer.deploy(RaidBasic, game.address);

    await token.transferFrom(token.address, game.address, "500000000000000000000000");
    // This next bit is temporary, we'll handle approvals through the frontend somehow
    await token.approve(game.address, "1000000000000000000000000");
    await game.giveMeSkill("1000000000000000000000"); // 1000 skill, test token value is $5 usd
    await game.mintCharacter();
  }
};
