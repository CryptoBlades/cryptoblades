const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');

const SkillToken = artifacts.require('SkillToken');
const CryptoBlades = artifacts.require('CryptoBlades');
const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');
const DummyRandoms = artifacts.require('DummyRandoms');
const DummyPriceService = artifacts.require('DummyPriceService');

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

    await characters.setMain(accounts[0]);
  });

  describe('getRequiredXpForLevel', () => {
    it('should work', async () => {
      const requiredXp = await characters.getRequiredXpForNextLevel(3);

      assert.strictEqual(requiredXp.toNumber(), 19);
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
});

contract('CryptoBlades', accounts => {
  let token, cryptoBlades, characters, weapons, priceChecker, randoms;
  beforeEach(async () => {
    token = await SkillToken.deployed();

    cryptoBlades = await CryptoBlades.new();
    characters = await Characters.new();
    weapons = await Weapons.new();
    priceChecker = await DummyPriceService.new();
    randoms = await DummyRandoms.new();

    await Promise.all([
      cryptoBlades.initialize(token.address, characters.address, weapons.address, priceChecker.address, randoms.address),
      characters.initialize().then(() => characters.setMain(cryptoBlades.address)),
      weapons.initialize().then(() => weapons.setMain(cryptoBlades.address)),
      randoms.initialize().then(() => randoms.setMain(cryptoBlades.address)),
      token.approve(cryptoBlades.address, '100' + '0'.repeat(18)),
    ]);
  });

  describe('needsRandom', () => {
    it('causes a revert if no random seed is available', async () => {
      assert.isFalse(await cryptoBlades.hasRandom());

      await expectRevert(cryptoBlades.mintCharacter({ from: accounts[0] }), "Sender has no random seed");
    });

    it('works if the sender has a random seed', async () => {
      await cryptoBlades.requestRandom(); // random is fulfilled immediately in dummy impl

      assert.isTrue(await cryptoBlades.hasRandom());

      const res = await cryptoBlades.mintCharacter({ from: accounts[0] });
      assert.isObject(res);
    });
  });

  describe('mintCharacter', () => {
    it('should work', async () => {
      await cryptoBlades.requestRandom(); // random is fulfilled immediately in dummy impl

      const { tx } = await cryptoBlades.mintCharacter({ from: accounts[0] });

      await expectEvent.inTransaction(tx, characters, 'NewCharacter', { character: '0', minter: accounts[0] });
    });

    it('consumes random', async () => {
      await cryptoBlades.requestRandom(); // random is fulfilled immediately in dummy impl

      assert.isTrue(await cryptoBlades.hasRandom());

      const res = await cryptoBlades.mintCharacter({ from: accounts[0] });
      assert.isObject(res);

      assert.isFalse(await cryptoBlades.hasRandom());
    });
  });
});
