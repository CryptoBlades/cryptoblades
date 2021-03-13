const Kryptoknights = artifacts.require('Kryptoknights');
const Characters = artifacts.require('Characters');

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
