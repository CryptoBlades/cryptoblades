const BigNumber = require('bignumber.js');

const SkillStakingRewardsUpgradeable = artifacts.require('SkillStakingRewardsUpgradeable');
const SkillToken = artifacts.require('SkillToken');
const CryptoBlades = artifacts.require('CryptoBlades');
const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');
const BasicPriceOracle = artifacts.require('BasicPriceOracle');
const DummyRandoms = artifacts.require('DummyRandoms');
const Promos = artifacts.require('Promos');

SkillStakingRewardsUpgradeable.numberFormat = 'String';
SkillToken.numberFormat = 'String';
CryptoBlades.numberFormat = 'String';
Characters.numberFormat = 'String';
Weapons.numberFormat = 'String';
BasicPriceOracle.numberFormat = 'String';
DummyRandoms.numberFormat = 'String';
Promos.numberFormat = 'String';

contract('CryptoBlades', accounts => {
  let skill, sr, charas, weps, po, randoms, game, promos;
  beforeEach(async () => {
    skill = await SkillToken.deployed();

    await Promise.all([
      SkillStakingRewardsUpgradeable.new().then(c => sr = c),
      CryptoBlades.new().then(c => game = c),
      Weapons.new().then(c => weps = c),
      Promos.new().then(c => promos = c),

      Characters.deployed().then(c => charas = c),
      BasicPriceOracle.deployed().then(c => po = c),
      DummyRandoms.deployed().then(c => randoms = c),
    ]);

    await Promise.all([
      sr.initialize(accounts[0], accounts[0], skill.address, skill.address, 0),
      game.initialize(skill.address, charas.address, weps.address, po.address, randoms.address),
      weps.initialize(),
      promos.initialize(),
    ]);

    await weps.migrateTo_surprise(promos.address);
    await game.migrateTo_23b3a8b(sr.address);
    await sr.migrateTo_23b3a8b(game.address);

    const GAME_ADMIN = web3.utils.soliditySha3({ type: 'string', value: 'GAME_ADMIN' });
    await weps.grantRole(GAME_ADMIN, game.address);
    await weps.grantRole(GAME_ADMIN, accounts[0]);

    await po.setCurrentPrice('100'); // 100 SKILL wei per USD
    await game.setWeaponMintValue('100'); // 1 USD
    await game.setReforgeWeaponValue('100'); // 1 USD
  });

  afterEach(async () => {
    await sr.exit();
  });

  async function performTest(startingStakedSkillAmount, expectedStakedSkillAmountAfter, fn) {
    await skill.approve(game.address, '0');

    await skill.approve(sr.address, startingStakedSkillAmount);
    await sr.stake(startingStakedSkillAmount);

    await fn();

    const stakedSkillBalanceAfter = new BigNumber(await sr.balanceOf(accounts[0]));

    assert.isTrue(stakedSkillBalanceAfter.minus(expectedStakedSkillAmountAfter).abs().lte('1'));
  }

  describe('weapon minting', () => {
    describe('x1', () => {
      it('should be payable using only staked SKILL', async () => {
        await performTest('100', '20', async () => {
          await game.mintWeaponUsingStakedSkill();
        });
      });
    });

    describe('x10', () => {
      it('should be payable using only staked SKILL', async () => {
        await performTest('1000', '200', async () => {
          await game.mintWeaponNUsingStakedSkill('10');
        });
      });
    });
  });
});

