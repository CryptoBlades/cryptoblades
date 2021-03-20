const CryptoBlades = artifacts.require('CryptoBlades');
const Characters = artifacts.require('Characters');

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

contract('CryptoBlades', accounts => {
  describe('mintCharacter', () => {
    it('should work', async () => {
      const cryptoBlades = await CryptoBlades.deployed();
      const characters = await Characters.at(await cryptoBlades.characters());

      await cryptoBlades.mintCharacter({ from: accounts[0] });

      const events = await characters.getPastEvents();
      assertEventEmitted(events, 'NewCharacter', 1);
    });
  });

  describe('characters.getRequiredXpForLevel', () => {
    it('should work', async () => {
      const cryptoBlades = await CryptoBlades.deployed();
      const characters = await Characters.at(await cryptoBlades.characters());

      const requiredXp = await characters.getRequiredXpForNextLevel(3);

      assert.strictEqual(requiredXp.toNumber(), 19);
    });
  });

  describe('characters.gainXp', () => {
    it('should work', async () => {
      const cryptoBlades = await CryptoBlades.deployed();
      const characters = await Characters.at(await cryptoBlades.characters());

      await cryptoBlades.mintCharacter({ from: accounts[0] });

      const events = await characters.getPastEvents();
      assertEventEmitted(events, 'NewCharacter', 2);

      try {
        await characters.gainXp(2, 1000);
        assert.fail('Expected setXp to throw error');
      }
      catch (e) {
        assert.match(e.message, /Reason given: Can only be called by main file/g);
      }
    });
  });
});
