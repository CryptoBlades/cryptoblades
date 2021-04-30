const SkillToken = artifacts.require('SkillToken');
const CryptoBlades = artifacts.require('CryptoBlades');
const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');

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
  let token, cryptoBlades, characters, weapons;
  beforeEach(async () => {
    token = await SkillToken.deployed();

    cryptoBlades = await CryptoBlades.new();
    characters = await Characters.new();
    weapons = await Weapons.new();

    await Promise.all([
      cryptoBlades.initialize(token.address, characters.address, weapons.address),
      characters.initialize().then(() => characters.setMain(cryptoBlades.address)),
      weapons.initialize().then(() => weapons.setMain(cryptoBlades.address)),
    ]);
  });

  describe('mintCharacter', () => {
    it('should work', async () => {
      await cryptoBlades.mintCharacter({ from: accounts[0] });

      const events = await characters.getPastEvents();
      assertEventEmitted(events, 'NewCharacter', 0);
    });
  });
});
