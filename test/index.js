const Kryptoknights = artifacts.require('Kryptoknights');

contract('Kryptoknights', accounts => {
  describe('_name', () => {
    it('contains string', async () => {
      const instance = await Kryptoknights.deployed();

      const res = await instance._name.call();

      assert.equal(res, 'Krypto knights!');
    });
  });

  describe('getName', () => {
    it('should return string', async () => {
      const instance = await Kryptoknights.deployed();

      const res = await instance.getName.call();

      assert.equal(res, 'Krypto knights!');
    });
  });
});
