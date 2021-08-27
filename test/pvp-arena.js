const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const _ = require('lodash');
const BigNumber = require('bignumber.js');
const web3 = require('web3');

const SkillToken = artifacts.require('SkillToken');
const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');
const PvpArena = artifacts.require('PvpArena');
const BasicPriceOracle = artifacts.require('BasicPriceOracle');
const NFTMarket = artifacts.require('NFTMarket');

contract('PvpArena', accounts => {
  let pvpArena, characters, weapons;
  beforeEach(async () => {
    skillToken = await SkillToken.deployed();
    characters = await Characters.deployed();
    weapons = await Weapons.deployed();
    pvpArena = await PvpArena.deployed();
    priceOracle = await BasicPriceOracle.deployed();
    market = await NFTMarket.deployed();

    // TODO: Check if this is right
    await characters.grantRole(await characters.GAME_ADMIN(), accounts[0]);
    await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[0]);
    await characters.setCharacterLimit(100);
    await market.grantRole(await market.GAME_ADMIN(), accounts[0]);
    await skillToken.transferFrom(skillToken.address, accounts[1], web3.utils.toWei('10', 'ether'));
    
    await priceOracle.setCurrentPrice('100');
  });

  // TODO: move to test utilities
  async function createCharacter() {
    console.log('Minting a character');
    const { tx: mintCharaTx } = await characters.mint(accounts[1], '123');

    console.log('[DONE] Minting a character')
    const newCharaEvt = await expectEvent.inTransaction(mintCharaTx, characters, 'NewCharacter', { minter: accounts[0] });
    return newCharaEvt.args.character;
  }

  describe('#enterArena', () => {
    let characterId;
    let character;
    let enterArenaReceipt;

    describe('happy path', async () => {
      beforeEach(async () => {
        characterId = await createCharacter();
        character = await characters.get(characterId);

        const cost = await pvpArena.getEntryCost(characterId);
        console.log(`cost`, cost)
        await skillToken.approve(pvpArena.address, cost);
        const enterArenaTx = await pvpArena.enterArena(characterId);
        enterArenaReceipt = await enterArenaTx.wait();
      });

      it('should lock the entry cost', async () => {
        const cost = await pvpArena.getEntryCost(characterId);
        await expectEvent(receipt, 'EntryCostLocked', { owner: accounts[0], spender: pvpArena.address, value: cost });
      });
    });
  });
});