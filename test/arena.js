
const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const _ = require('lodash');

const SkillToken = artifacts.require('SkillToken');
const CryptoBlades = artifacts.require('CryptoBlades');
const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');
const DummyRandoms = artifacts.require('DummyRandoms');
const BasicPriceOracle = artifacts.require('BasicPriceOracle');
const Arena = artifacts.require('Arena');

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

contract("Arena", accounts => {

    var token, arena, cryptoBlades, characters, weapons, priceChecker, randoms;

    beforeEach(async () => {
        token = await SkillToken.deployed();
        cryptoBlades = await CryptoBlades.new();
        characters = await Characters.deployed();
        weapons = await Weapons.deployed();
        priceChecker = await BasicPriceOracle.new();
        randoms = await DummyRandoms.new();
        arena = await Arena.new();

        const GAME_ADMIN = await cryptoBlades.GAME_ADMIN();

        await Promise.all([
            cryptoBlades.initialize(token.address, characters.address, weapons.address, priceChecker.address, randoms.address),
            priceChecker.initialize().then(() => priceChecker.setCurrentPrice(web3.utils.toWei('0.2', 'ether'))),
            randoms.initialize().then(() => randoms.setMain(cryptoBlades.address)),
            token.approve(cryptoBlades.address, web3.utils.toWei('100', 'ether')),
            token.approve(arena.address, web3.utils.toWei('100', 'ether')),
            characters.grantRole(GAME_ADMIN, accounts[0]),
            weapons.grantRole(GAME_ADMIN, accounts[0]),
            arena.initialize(cryptoBlades.address)
        ]);
    });

    describe('enterArena', () => {
        it('should work', async () => {
            await characters.mint(accounts[0], 12312)
            await weapons.mint(accounts[0], 12312)
            await arena.enterArena(0, 0, 1)
            await arena.leaveArena()
        });
    });
  
});