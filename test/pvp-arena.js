const web3 = require('web3');
const { expectRevert } = require('@openzeppelin/test-helpers');
const helpers = require('./helpers');

const SkillToken = artifacts.require('SkillToken');
const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');
const Shields = artifacts.require('Shields');
const PvpArena = artifacts.require('PvpArena');
const BasicPriceOracle = artifacts.require('BasicPriceOracle');

contract('PvpArena', accounts => {
  let pvpArena, characters, weapons;
  beforeEach(async () => {
    skillToken = await SkillToken.deployed();
    characters = await Characters.deployed();
    weapons = await Weapons.deployed();
    shields = await Shields.deployed();
    pvpArena = await PvpArena.deployed();
    priceOracle = await BasicPriceOracle.deployed();

    // TODO: Check if this is right
    await characters.grantRole(await characters.GAME_ADMIN(), accounts[0]);
    await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[1]);
    await weapons.grantRole(await weapons.GAME_ADMIN(), accounts[0]);
    await shields.grantRole(await shields.GAME_ADMIN(), accounts[0]);

    await skillToken.transferFrom(skillToken.address, accounts[1], web3.utils.toWei('10', 'ether'));
    
    await priceOracle.setCurrentPrice('10');
  });


  describe('#getArenaTier', () => {
    let character0Id;
    let character1Id;
    
    beforeEach(async () => {
      character0Id = await helpers.createCharacter(accounts[1], '123', { characters });
      character1Id = await helpers.createCharacter(accounts[1], '456', { characters });
      
      await characters.gainXp(character0Id, 190);
      await characters.gainXp(character1Id, 220);
    });

    it('should return the right arena tier', async () => {
      const character0arenaTier = await pvpArena.getArenaTier(character0Id, { from: accounts[1] });
      const character1arenaTier = await pvpArena.getArenaTier(character1Id, { from: accounts[1] });
      expect(character0arenaTier.toString()).to.equal('0');
      expect(character1arenaTier.toString()).to.equal('1');
    });
  });

  describe('#enterArena', () => {
    let characterId;
    let weaponId;
    let shieldId;
    let cost;

    beforeEach(async () => {
      weaponId = await helpers.createWeapon(accounts[1], '123', { weapons });
      shieldId = await helpers.createShield(accounts[1], '123', { shields });
      characterId = await helpers.createCharacter(accounts[1], '123', { characters });
    });

    describe('happy path', async () => {
      let enterArenaReceipt;

      beforeEach(async () => {
        cost = await pvpArena.getEntryCost(characterId, { from: accounts[1] });
        await skillToken.approve(pvpArena.address, cost, { from: accounts[1] });
        enterArenaReceipt = await pvpArena.enterArena(characterId, weaponId, { from: accounts[1] });
      });

      it('should lock the entry cost');

      it('should add the character with its weapon and shield to the fighters list');
    });

    describe('character unavailable', async () => {
      let weapon2Id;

      beforeEach(async () => {
        weapon2Id = await helpers.createWeapon(accounts[1], '123', { weapons });

        cost = await pvpArena.getEntryCost(characterId);
        await skillToken.approve(pvpArena.address, cost, { from: accounts[1] });
        await pvpArena.enterArena(characterId, weaponId, { from: accounts[1] });
      });

      it('should revert', async () => {
        await expectRevert(pvpArena.enterArena(characterId, weapon2Id, { from: accounts[1] }));
      });
    });

    describe('weapon unavailable', async () => {
      beforeEach(async () => {
        character2Id = await helpers.createCharacter(accounts[1], '443', { characters });

        cost = await pvpArena.getEntryCost(characterId, { from: accounts[1] });
        await skillToken.approve(pvpArena.address, cost, { from: accounts[1] });
        await pvpArena.enterArena(characterId, weaponId, { from: accounts[1] });
      });

      it('should revert', async () => {
        await expectRevert(pvpArena.enterArena(character2Id, weaponId, { from: accounts[1] })); 
      });
    });

    describe('shield unavailable', () => {
      beforeEach(async () => {
        character2Id = await helpers.createCharacter(accounts[1], '152', { characters });
        weapon2Id = await helpers.createWeapon(accounts[1], '123', { weapons });
        shieldId = await helpers.createShield(accounts[1], '446', { shields });

        cost = await pvpArena.getEntryCost(characterId, { from: accounts[1] });
        await skillToken.approve(pvpArena.address, cost, { from: accounts[1] })
        // await pvpArena.enterArena(characterId, weaponId, shieldId, { from: accounts[1] })
      });

      it('should revert', async () => {
        // await expectRevert(pvpArena.enterArena(character2Id, weapon2Id, shieldId, { from: accounts[1] }));
      })
    });

    describe('character is not sender\'s', () => {
      beforeEach(async () => {
        cost = await pvpArena.getEntryCost(characterId, { from: accounts[1] });
        await skillToken.approve(pvpArena.address, cost, { from: accounts[1] });
        await pvpArena.enterArena(characterId, weaponId, { from: accounts[1] });
      });
    });
  });
});