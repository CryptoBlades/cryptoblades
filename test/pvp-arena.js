const web3 = require("web3");
const { expectRevert, time } = require("@openzeppelin/test-helpers");
const helpers = require("./helpers");

const SkillToken = artifacts.require("SkillToken");
const Characters = artifacts.require("Characters");
const Weapons = artifacts.require("Weapons");
const Shields = artifacts.require("Shields");
const PvpArena = artifacts.require("PvpArena");
const BasicPriceOracle = artifacts.require("BasicPriceOracle");

contract("PvpArena", (accounts) => {
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

    await skillToken.transferFrom(
      skillToken.address,
      accounts[1],
      web3.utils.toWei("10", "ether")
    );
    await skillToken.transferFrom(
      skillToken.address,
      accounts[3],
      web3.utils.toWei("10", "ether")
    );

    await priceOracle.setCurrentPrice("10");
  });

  describe("#getArenaTier", () => {
    let character0Id;
    let character1Id;

    beforeEach(async () => {
      character0Id = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
      character1Id = await helpers.createCharacter(accounts[1], "456", {
        characters,
      });

      await characters.gainXp(character0Id, 190);
      await characters.gainXp(character1Id, 220);
    });

    it("should return the right arena tier", async () => {
      const character0arenaTier = await pvpArena.getArenaTier(character0Id, {
        from: accounts[1],
      });
      const character1arenaTier = await pvpArena.getArenaTier(character1Id, {
        from: accounts[1],
      });
      expect(character0arenaTier.toString()).to.equal("0");
      expect(character1arenaTier.toString()).to.equal("1");
    });
  });

  describe("#enterArena", () => {
    let characterId;
    let weaponId;
    let shieldId;
    let cost;

    beforeEach(async () => {
      weaponId = await helpers.createWeapon(accounts[1], "123", { weapons });
      shieldId = await helpers.createShield(accounts[1], "123", { shields });
      characterId = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
    });

    describe("happy path", async () => {
      let enterArenaReceipt;

      beforeEach(async () => {
        cost = await pvpArena.getEntryWager(characterId, { from: accounts[1] });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        enterArenaReceipt = await pvpArena.enterArena(
          characterId,
          weaponId,
          0,
          false,
          {
            from: accounts[1],
          }
        );
      });

      it("should lock duelCost from wagered skill");

      it("should add the character with its weapon and shield to the arena", async () => {
        const isCharacterInArena = await pvpArena.isCharacterInArena(
          characterId
        );

        expect(isCharacterInArena).to.equal(true);
      });
    });

    describe("character already in arena", () => {
      let weapon2Id;

      beforeEach(async () => {
        await helpers.createWeapon(accounts[1], "123", { weapons });
        weapon2Id = await helpers.createWeapon(accounts[1], "123", { weapons });
        characterId = await helpers.createCharacter(accounts[1], "123", {
          characters,
        });
        pvpArena.enterArena(characterId, weaponId, 0, false, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        await expectRevert(
          pvpArena.enterArena(characterId, weapon2Id, 0, false, {
            from: accounts[1],
          }),
          "The character is already in the arena"
        );
      });
    });

    describe("weapon already in arena", () => {
      beforeEach(async () => {
        character2Id = await helpers.createCharacter(accounts[1], "443", {
          characters,
        });

        cost = await pvpArena.getEntryWager(characterId, { from: accounts[1] });

        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        await pvpArena.enterArena(characterId, weaponId, 0, false, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        cost = await pvpArena.getEntryWager(character2Id, {
          from: accounts[1],
        });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });

        await expectRevert(
          pvpArena.enterArena(character2Id, weaponId, 0, false, {
            from: accounts[1],
          }),
          "The weapon is already in the arena"
        );
      });
    });

    describe("shield already in arena", () => {
      beforeEach(async () => {
        character2Id = await helpers.createCharacter(accounts[1], "152", {
          characters,
        });

        weapon2Id = await helpers.createWeapon(accounts[1], "123", { weapons });
        shieldId = await helpers.createShield(accounts[1], "446", { shields });

        cost = await pvpArena.getEntryWager(character2Id, {
          from: accounts[1],
        });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        await pvpArena.enterArena(characterId, weaponId, shieldId, true, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        cost = await pvpArena.getEntryWager(character2Id, {
          from: accounts[1],
        });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });

        await expectRevert(
          pvpArena.enterArena(character2Id, weapon2Id, shieldId, true, {
            from: accounts[1],
          }),
          "The shield is already in the arena"
        );
      });
    });

    describe("character is not sender's", () => {
      let otherCharacterId;

      beforeEach(async () => {
        otherCharacterId = await helpers.createCharacter(accounts[2], "123", {
          characters,
        });

        cost = await pvpArena.getEntryWager(characterId, {
          from: accounts[1],
        });

        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        await expectRevert(
          pvpArena.enterArena(otherCharacterId, weaponId, 0, false, {
            from: accounts[1],
          }),
          "You don't own the given character"
        );
      });
    });

    describe("character is in a raid", () => {
      it("should revert", () => {});
    });

    describe("weapon is in a raid", () => {
      it("should revert", () => {});
    });
  });

  describe("#getMyParticipatingCharacters", () => {
    let character1Id;
    let character2Id;

    beforeEach(async () => {
      character1Id = await helpers.createCharacter(accounts[3], "123", {
        characters,
      });
      const weapon1Id = await helpers.createWeapon(accounts[3], "125", {
        weapons,
      });
      character2Id = await helpers.createCharacter(accounts[3], "125", {
        characters,
      });
      const weapon2Id = await helpers.createWeapon(accounts[3], "123", {
        weapons,
      });

      cost = await pvpArena.getEntryWager(character1Id, {
        from: accounts[3],
      });
      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[3],
      });
      await pvpArena.enterArena(character1Id, weapon1Id, 0, false, {
        from: accounts[3],
      });
      cost = await pvpArena.getEntryWager(character2Id, {
        from: accounts[3],
      });
      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[3],
      });
      await pvpArena.enterArena(character2Id, weapon2Id, 0, false, {
        from: accounts[3],
      });
    });

    it("should return the ids of the characters I have in the arena", async () => {
      const myParticipatingCharacters =
        await pvpArena.getMyParticipatingCharacters({ from: accounts[3] });

      expect(myParticipatingCharacters[0].toString()).to.equal(
        character1Id.toString()
      );
      expect(myParticipatingCharacters[1].toString()).to.equal(
        character2Id.toString()
      );
    });
  });

  describe("#leaveArena", () => {});
});
