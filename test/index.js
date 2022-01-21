const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const _ = require('lodash');

const SkillToken = artifacts.require('SkillToken');
const CryptoBlades = artifacts.require('CryptoBlades');
const Characters = artifacts.require('Characters');
Characters.numberFormat = 'String';
const Weapons = artifacts.require('Weapons');
const DummyRandoms = artifacts.require('DummyRandoms');
const BasicPriceOracle = artifacts.require('BasicPriceOracle');

function assertEventEmitted(events, eventName, ...args) {
  assert.isTrue(events.some(log => {
    if (log.event !== eventName) {
      return false;
    }

    for (let i = 0; i < args.length; i++) {
      if (args[i] != log.returnValues[i]) {
        return false;
      }
    }

    return true;
  }), `Expected event '${eventName}(${args.map(arg => '' + arg).join(', ')})' to be emitted`);
}

contract('Characters', accounts => {
  let characters;
  beforeEach(async () => {
    characters = await Characters.new();

    await characters.initialize();

    const GAME_ADMIN = await characters.GAME_ADMIN();

    await characters.grantRole(GAME_ADMIN, accounts[0]);
  });

  describe('getRequiredXpForLevel', () => {
    it('should work', async () => {
      const requiredXp = await characters.getRequiredXpForNextLevel(3);

      assert.strictEqual(requiredXp, '19');
    });
  });

  describe('gainXp', () => {
    it('should work', async () => {
      await characters.mint(accounts[0], '123');

      const events = await characters.getPastEvents();
      assertEventEmitted(events, 'NewCharacter', 0);

      await characters.gainXp(0, 1000);

      const [lv, xp] = await Promise.all([
        characters.getLevel(0), characters.getXp(0)
      ]);

      assert.strictEqual(lv.toString(), '23');
      assert.strictEqual(xp.toString(), '22');
    });
  });

  describe('transfer', () => {
    it('disallows recipient to have more than 4 characters', async () => {
      await Promise.all(_.range(4).map(async idx => {
        const { tx } = await characters.mint(accounts[0], idx);

        const evt = await expectEvent.inTransaction(tx, characters, 'NewCharacter', { minter: accounts[0] });

        await characters.safeTransferFrom(accounts[0], accounts[1], evt.args.character);
      }));

      assert.strictEqual(await characters.balanceOf(accounts[1]), '4');

      const { tx } = await characters.mint(accounts[0], '111');

      const evt = await expectEvent.inTransaction(tx, characters, 'NewCharacter', { minter: accounts[0] });

      await expectRevert(characters.safeTransferFrom(accounts[0], accounts[1], evt.args.character), "Recv has too many characters");
    });
  });
});

contract('CryptoBlades', accounts => {
  let token, cryptoBlades, characters, weapons, priceChecker, randoms;
  beforeEach(async () => {
    token = await SkillToken.deployed();

    cryptoBlades = await CryptoBlades.new();
    characters = await Characters.new();
    weapons = await Weapons.new();
    priceChecker = await BasicPriceOracle.new();
    randoms = await DummyRandoms.new();

    const GAME_ADMIN = await cryptoBlades.GAME_ADMIN();

    await Promise.all([
      cryptoBlades.initialize(token.address, characters.address, weapons.address, priceChecker.address, randoms.address),
      priceChecker.initialize().then(() => priceChecker.setCurrentPrice(web3.utils.toWei('0.2', 'ether'))),
      characters.initialize().then(() => characters.grantRole(GAME_ADMIN, cryptoBlades.address)),
      weapons.initialize().then(() => weapons.grantRole(GAME_ADMIN, cryptoBlades.address)),
      randoms.initialize().then(() => randoms.setMain(cryptoBlades.address)),
      token.approve(cryptoBlades.address, web3.utils.toWei('100', 'ether')),
    ]);
  });

  describe('mintCharacter', () => {
    it('should work', async () => {
      const { tx } = await cryptoBlades.mintCharacter({ from: accounts[0] });

      await expectEvent.inTransaction(tx, characters, 'NewCharacter', { character: '0', minter: accounts[0] });
    });
  });
});
