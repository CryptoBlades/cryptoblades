const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const util = require('util');
const path = require('path');
const fs = require('fs');

const SkillToken = artifacts.require("SkillToken");
const ExperimentToken = artifacts.require("ExperimentToken");
const ExperimentToken2 = artifacts.require("ExperimentToken2");
const CryptoBlades = artifacts.require("CryptoBlades");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const DummyPriceService = artifacts.require("DummyPriceService");
const DummyRandoms = artifacts.require("DummyRandoms");
// const ChainlinkRandoms = artifacts.require("ChainlinkRandoms");
const SkillStakingRewardsUpgradeable = artifacts.require("SkillStakingRewardsUpgradeable");
const LPStakingRewardsUpgradeable = artifacts.require("LPStakingRewardsUpgradeable");
const LP2StakingRewardsUpgradeable = artifacts.require("LP2StakingRewardsUpgradeable");
const RaidBasic = artifacts.require("RaidBasic");

writeFileAsync = util.promisify(fs.writeFile);

module.exports = async function (deployer, network, accounts) {
  if (network === 'development' || network === 'development-fork') {
    await deployer.deploy(SkillToken);
    const token = await SkillToken.deployed();

    await deployer.deploy(ExperimentToken);
    const expToken = await ExperimentToken.deployed();

    await deployer.deploy(ExperimentToken2);
    const expToken2 = await ExperimentToken2.deployed();

    const charas = await deployProxy(Characters, [], { deployer });

    const weps = await deployProxy(Weapons, [], { deployer });

    const priceChecker = await deployer.deploy(DummyPriceService);

    const randoms = await deployProxy(DummyRandoms, [], { deployer });
    // const randoms = await deployer.deploy(ChainlinkRandoms);

    const game = await deployProxy(CryptoBlades, [token.address, charas.address, weps.address, priceChecker.address, randoms.address], { deployer });

    await charas.setMain(game.address);
    await weps.setMain(game.address);
    await randoms.setMain(game.address);

    await deployProxy(SkillStakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, token.address, 60], { deployer });
    await deployProxy(LPStakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, expToken.address, 0], { deployer });
    await deployProxy(LP2StakingRewardsUpgradeable, [accounts[0], accounts[0], token.address, expToken2.address, 0], { deployer });

    await deployProxy(RaidBasic, [game.address], { deployer });

    await token.transferFrom(token.address, game.address, "500000000000000000000000");
    await expToken.transferFrom(expToken.address, accounts[0], '599' + '0'.repeat(18));
    await expToken2.transferFrom(expToken2.address, accounts[0], '699' + '0'.repeat(18));
    // This next bit is temporary, we'll handle approvals through the frontend somehow
    await token.approve(game.address, "1000000000000000000000000");
    await game.giveMeSkill("1000000000000000000000"); // 1000 skill, test token value is $5 usd
    // await game.mintCharacter();
  }
};
