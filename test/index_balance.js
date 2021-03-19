const Kryptoknights = artifacts.require('Kryptoknights');
const Characters = artifacts.require('Characters');

//stress test
//turn stamina off so we dont have to wait for days

// test 1
// mint 1000 characters
// battle for 10 days without addional mints (daily fights: 10)
// output contract balance
// output player wealth: total and richest player

// test 2
// mint 1000 characters
// craft as soon as the user has enough to mint (keep battling until then)
// use the strongest weapon they have .getPowerMultiplierForTrait(wepId,charTrait)
// 10 day duration
// output contract balance
// output player wealth: total and richest player

// test 3
// mint 1000 characters
// output 

contract('Kryptoknights', accounts => {
  describe('mintCharacter', () => {
    it('should work', async () => {
      const instance = await Kryptoknights.deployed();

      const res = await instance.mintCharacter({ from: accounts[2], value: web3.utils.toWei("5", "ether") });

      assert.equal(res.logs[0].event, 'NewCharacter');
      assert.equal(res.logs[0].args.character.toNumber(), 0);
    });
  });

  describe('characters.getRequiredXpForLevel', () => {
    it('should work', async () => {
      const instance = await Kryptoknights.deployed();

      const charactersContractAddress = await instance.characters.call();

      const characters = await Characters.at(charactersContractAddress);

      const requiredXp = await characters.getRequiredXpForLevel.call(3);

      assert.strictEqual(requiredXp.toNumber(), 18);
    });
  });

  describe('characters.setXp', () => {
    it('should work', async () => {
      const instance = await Kryptoknights.deployed();

      const mintRes = await instance.mintCharacter({ from: accounts[1], value: web3.utils.toWei("5", "ether") });

      const characterId = mintRes.logs[0].args.character.toNumber();

      const charactersContractAddress = await instance.characters.call();

      const characters = await Characters.at(charactersContractAddress);

      try {
        await characters.setXp(characterId, 1000);
        assert.fail('Expected setXp to throw error');
      }
      catch(e) {
        assert.match(e.message, /Reason given: Can only be called by main file/g);
      }
    });
  });
});
