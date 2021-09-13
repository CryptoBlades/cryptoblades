const web3 = require("web3");
const {
  expectRevert,
  expectEvent,
  time,
} = require("@openzeppelin/test-helpers");
const helpers = require("./helpers");

const { BN, toBN } = web3.utils;

contract("PvpArena", (accounts) => {
  let pvpArena, characters, weapons, shields, priceOracle, randoms;

  async function createCharacterInPvpTier(account, tier, seed = "123") {
    const characterID = await helpers.createCharacter(account, seed, {
      characters,
    });
    const weaponID = await helpers.createWeapon(account, seed, 0, {
      weapons,
    });

    await helpers.levelUpTo(characterID, tier * 10, { characters });

    const cost = await pvpArena.getEntryWager(characterID, { from: account });

    await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
      from: account,
    });
    await pvpArena.enterArena(characterID, weaponID, 0, false, {
      from: account,
    });

    return characterID;
  }

  beforeEach(async () => {
    contracts = await helpers.prepareContracts(accounts);
    skillToken = contracts.skillToken;
    characters = contracts.characters;
    weapons = contracts.weapons;
    shields = contracts.shields;
    randoms = contracts.randoms;
    priceOracle = contracts.priceOracle;
    pvpArena = contracts.pvpArena;

    await priceOracle.setCurrentPrice(web3.utils.toWei("1", "ether")); // 1/5 SKILL per USD, AKA 5 USD per SKILL

    await skillToken.transferFrom(
      skillToken.address,
      accounts[1],
      web3.utils.toWei("1", "kether")
    );
    await skillToken.transferFrom(
      skillToken.address,
      accounts[2],
      web3.utils.toWei("1", "kether")
    );
    await skillToken.transferFrom(
      skillToken.address,
      accounts[3],
      web3.utils.toWei("1", "kether")
    );

    await characters.grantRole(await characters.GAME_ADMIN(), accounts[0]);
    await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[1]);
    await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[2]);
    await weapons.grantRole(await weapons.GAME_ADMIN(), accounts[0]);
    await shields.grantRole(await shields.GAME_ADMIN(), accounts[0]);
  });

  describe("#getDuelCost", () => {
    it("should return the correct cost", async () => {
      const tier = 5;
      const charID = await createCharacterInPvpTier(accounts[1], tier, "888");
      const cost = await pvpArena.getDuelCost(charID, { from: accounts[1] });

      expect(cost.toString()).to.be.equal(web3.utils.toWei("7.5"));
    });
  });

  describe("#getMyParticipatingWeapons", () => {
    it("should return the sender's weapons currently in the arena", async () => {
      const charID = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
      const weaponID = await helpers.createWeapon(accounts[1], "123", 0, {
        weapons,
      });

      const cost = await pvpArena.getEntryWager(charID, { from: accounts[1] });

      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[1],
      });
      await pvpArena.enterArena(charID, weaponID, 0, false, {
        from: accounts[1],
      });

      const myWeapons = await pvpArena.getMyParticipatingWeapons({
        from: accounts[1],
      });

      expect(myWeapons[0].toString()).to.equal(weaponID.toString());
    });
  });

  describe("#getMyParticipatingShields", () => {
    it("should return the sender's shields currently in the arena", async () => {
      const charID = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
      const shieldID = await helpers.createShield(accounts[1], "123", {
        shields,
      });
      const weaponID = await helpers.createWeapon(accounts[1], "123", 0, {
        weapons,
      });

      const cost = await pvpArena.getEntryWager(charID, { from: accounts[1] });

      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[1],
      });
      await pvpArena.enterArena(charID, weaponID, shieldID, true, {
        from: accounts[1],
      });

      const myShields = await pvpArena.getMyParticipatingShields({
        from: accounts[1],
      });

      expect(myShields[0].toString()).to.equal(shieldID.toString());
      expect(myShields.length).to.equal(1);
    });
  });

  describe("#getArenaTier", () => {
    let character0ID;
    let character1ID;

    beforeEach(async () => {
      character0ID = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
      character1ID = await helpers.createCharacter(accounts[1], "456", {
        characters,
      });

      await helpers.levelUpTo(character0ID, 9, { characters });
      await helpers.levelUpTo(character1ID, 10, { characters });
    });

    it("should return the right arena tier", async () => {
      const character0arenaTier = await pvpArena.getArenaTier(character0ID, {
        from: accounts[1],
      });
      const character1arenaTier = await pvpArena.getArenaTier(character1ID, {
        from: accounts[1],
      });
      expect(character0arenaTier.toString()).to.equal("0");
      expect(character1arenaTier.toString()).to.equal("1");
    });
  });

  describe("#enterArena", () => {
    let characterID;
    let weaponId;
    let shieldId;
    let cost;

    beforeEach(async () => {
      weaponId = await helpers.createWeapon(accounts[1], "123", 0, { weapons });
      shieldId = await helpers.createShield(accounts[1], "123", { shields });
      characterID = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
    });

    describe("happy path", async () => {
      let enterArenaReceipt;

      beforeEach(async () => {
        cost = await pvpArena.getEntryWager(characterID, { from: accounts[1] });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        enterArenaReceipt = await pvpArena.enterArena(
          characterID,
          weaponId,
          0,
          false,
          {
            from: accounts[1],
          }
        );
      });

      it("should leave the character temporarily unattackable", async () => {
        let isAttackable = await pvpArena.isCharacterAttackable(characterID);
        const unattackableSeconds = await pvpArena.unattackableSeconds();

        expect(isAttackable).to.equal(false);

        await time.increase(unattackableSeconds);

        isAttackable = await pvpArena.isCharacterAttackable(characterID);
        expect(isAttackable).to.equal(true);
      });

      it("should add the character with its weapon and shield to the arena", async () => {
        const isCharacterInArena = await pvpArena.isCharacterInArena(
          characterID
        );

        expect(isCharacterInArena).to.equal(true);
      });
    });

    describe("character already in arena", () => {
      let weapon2Id;

      beforeEach(async () => {
        await helpers.createWeapon(accounts[1], "123", 0, { weapons });
        weapon2Id = await helpers.createWeapon(accounts[1], "123", 0, {
          weapons,
        });
        characterID = await helpers.createCharacter(accounts[1], "123", {
          characters,
        });

        const cost = await pvpArena.getEntryWager(characterID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        pvpArena.enterArena(characterID, weaponId, 0, false, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        const cost = await pvpArena.getEntryWager(characterID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });

        await expectRevert(
          pvpArena.enterArena(characterID, weapon2Id, 0, false, {
            from: accounts[1],
          }),
          "Character already in arena"
        );
      });
    });

    describe("weapon already in arena", () => {
      beforeEach(async () => {
        character2ID = await helpers.createCharacter(accounts[1], "443", {
          characters,
        });

        cost = await pvpArena.getEntryWager(characterID, { from: accounts[1] });

        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        await pvpArena.enterArena(characterID, weaponId, 0, false, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        cost = await pvpArena.getEntryWager(character2ID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });

        await expectRevert(
          pvpArena.enterArena(character2ID, weaponId, 0, false, {
            from: accounts[1],
          }),
          "Weapon already in arena"
        );
      });
    });

    describe("shield already in arena", () => {
      beforeEach(async () => {
        character2ID = await helpers.createCharacter(accounts[1], "152", {
          characters,
        });

        weapon2Id = await helpers.createWeapon(accounts[1], "123", 0, {
          weapons,
        });
        shieldId = await helpers.createShield(accounts[1], "446", { shields });

        cost = await pvpArena.getEntryWager(character2ID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        await pvpArena.enterArena(characterID, weaponId, shieldId, true, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        cost = await pvpArena.getEntryWager(character2ID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });

        await expectRevert(
          pvpArena.enterArena(character2ID, weapon2Id, shieldId, true, {
            from: accounts[1],
          }),
          "Shield already in arena"
        );
      });
    });

    describe("character is not sender's", () => {
      let otherCharacterId;

      beforeEach(async () => {
        otherCharacterId = await helpers.createCharacter(accounts[2], "123", {
          characters,
        });

        cost = await pvpArena.getEntryWager(characterID, {
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
          "Not character owner"
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
    let character1ID;
    let character2ID;

    beforeEach(async () => {
      character1ID = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
      const weapon1Id = await helpers.createWeapon(accounts[1], "125", 0, {
        weapons,
      });
      character2ID = await helpers.createCharacter(accounts[1], "125", {
        characters,
      });
      const weapon2Id = await helpers.createWeapon(accounts[1], "123", 0, {
        weapons,
      });

      cost = await pvpArena.getEntryWager(character1ID, {
        from: accounts[1],
      });
      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[1],
      });
      await pvpArena.enterArena(character1ID, weapon1Id, 0, false, {
        from: accounts[1],
      });
      cost = await pvpArena.getEntryWager(character2ID, {
        from: accounts[1],
      });
      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[1],
      });
      await pvpArena.enterArena(character2ID, weapon2Id, 0, false, {
        from: accounts[1],
      });
    });

    it("should return the ids of the characters I have in the arena", async () => {
      const myParticipatingCharacters =
        await pvpArena.getMyParticipatingCharacters({ from: accounts[1] });

      expect(myParticipatingCharacters[0].toString()).to.equal(
        character1ID.toString()
      );
      expect(myParticipatingCharacters[1].toString()).to.equal(
        character2ID.toString()
      );
    });
  });

  describe("#requestOpponent", () => {
    let character1ID;
    let weapon1ID;

    beforeEach(async () => {
      character1ID = await helpers.createCharacter(accounts[1], "111", {
        characters,
      });
      weapon1ID = await helpers.createWeapon(accounts[1], "111", 0, {
        weapons,
      });
    });

    describe("finding opponents", () => {
      let character0ID;
      let character2ID;
      let character3ID;

      beforeEach(async () => {
        character0ID = await createCharacterInPvpTier(accounts[1], 2, "000");
        character2ID = await createCharacterInPvpTier(accounts[1], 3, "222");
        character3ID = await createCharacterInPvpTier(accounts[2], 2, "333");
      });

      it("should only pick characters from the same tier", async () => {
        await time.increase(await pvpArena.unattackableSeconds());

        const { tx } = await pvpArena.requestOpponent(character0ID, {
          from: accounts[1],
        });

        await expectEvent.inTransaction(tx, pvpArena, "NewDuel", {
          attacker: character0ID,
          defender: character3ID,
        });
      });

      it("should not consider characters owned by the sender", async () => {
        await time.increase(await pvpArena.unattackableSeconds());

        const characterID = await createCharacterInPvpTier(accounts[1], 8);

        await expectRevert(
          pvpArena.requestOpponent(characterID, {
            from: accounts[1],
          }),
          "No opponent found"
        );
      });

      it('should only consider "attackable" characters', async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 7);

        await time.increase(await pvpArena.unattackableSeconds());

        await createCharacterInPvpTier(accounts[2], 7);

        await expectRevert(
          pvpArena.requestOpponent(character1ID, {
            from: accounts[1],
          }),
          "No opponent found"
        );
      });
    });

    describe("character not in the arena", () => {
      it("should revert", async () => {
        await expectRevert(
          pvpArena.requestOpponent(character1ID, { from: accounts[1] }),
          "Character is not in the arena"
        );
      });
    });

    describe("opponent found", () => {
      it("emits the NewDuel event", async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 4);
        const character2ID = await createCharacterInPvpTier(accounts[2], 4);

        await time.increase(await pvpArena.unattackableSeconds());

        const { tx } = await pvpArena.requestOpponent(character1ID, {
          from: accounts[1],
        });

        await expectEvent.inTransaction(tx, pvpArena, "NewDuel", {
          attacker: character1ID,
          defender: character2ID,
        });
      });
    });

    describe("no opponent found", () => {
      it("should revert", async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 6);
        const character2ID = await createCharacterInPvpTier(accounts[2], 6);

        await expectRevert(
          pvpArena.requestOpponent(character1ID, {
            from: accounts[1],
          }),
          "No opponent found"
        );
      });
    });

    describe("decision time expired", () => {
      it("should revert");
    });
  });

  describe("#withdrawFromArena", () => {
    it("should withdraw the character from the arena", async () => {
      const character1ID = await createCharacterInPvpTier(
        accounts[1],
        2,
        "000"
      );
      const character2ID = await createCharacterInPvpTier(
        accounts[1],
        2,
        "221"
      );

      await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

      const myParticipatingCharacters =
        await pvpArena.getMyParticipatingCharacters({
          from: accounts[1],
        });

      const foundCharacter = myParticipatingCharacters.some((characterID) => {
        characterID.toString() === character1ID.toString();
      });

      expect(foundCharacter).to.equal(false);
      const isCharacterInArena = await pvpArena.isCharacterInArena(
        character1ID
      );
      expect(isCharacterInArena).to.equal(false);
    });

    it("should refund the wager", async () => {
      const character2ID = await createCharacterInPvpTier(
        accounts[1],
        1,
        "222"
      );
      const characterWager = await pvpArena.getCharacterWager(character2ID);
      const previousBalance = await skillToken.balanceOf(accounts[1]);
      await pvpArena.withdrawFromArena(character2ID, { from: accounts[1] });

      const newBalance = await skillToken.balanceOf(accounts[1]);

      expect(newBalance.toString()).to.equal(
        previousBalance.add(characterWager).toString()
      );
    });

    it("should return the wager minus the penalty if the character is in a duel", async () => {
      const character1ID = await createCharacterInPvpTier(
        accounts[1],
        4,
        "222"
      );
      await createCharacterInPvpTier(accounts[2], 4, "221");

      const characterWager = await pvpArena.getCharacterWager(character1ID);
      const previousBalance = await skillToken.balanceOf(accounts[1]);

      const wagerMinusPenalty = toBN(characterWager - characterWager * 0.25);

      await time.increase(await pvpArena.unattackableSeconds());
      await pvpArena.requestOpponent(character1ID, {
        from: accounts[1],
      });

      await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });
      const newBalance = await skillToken.balanceOf(accounts[1]);

      expect(newBalance.toString()).to.equal(
        previousBalance.add(wagerMinusPenalty).toString()
      );
    });

    it("should withdraw the character's weapon", async () => {
      const character1ID = await createCharacterInPvpTier(
        accounts[1],
        4,
        "222"
      );

      let myWeapons = await pvpArena.getMyParticipatingWeapons({
        from: accounts[1],
      });

      expect(myWeapons.length).to.equal(1);

      await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

      myWeapons = await pvpArena.getMyParticipatingWeapons({
        from: accounts[1],
      });

      expect(myWeapons.length).to.equal(0);
    });

    it("should withdraw the character's shield", async () => {
      const characterID = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
      const shieldID = await helpers.createShield(accounts[1], "123", {
        shields,
      });
      const weaponID = await helpers.createWeapon(accounts[1], "123", 0, {
        weapons,
      });

      const cost = await pvpArena.getEntryWager(characterID, {
        from: accounts[1],
      });

      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[1],
      });
      await pvpArena.enterArena(characterID, weaponID, shieldID, true, {
        from: accounts[1],
      });

      let myShields = await pvpArena.getMyParticipatingShields({
        from: accounts[1],
      });

      expect(myShields.length).to.equal(1);

      await pvpArena.withdrawFromArena(characterID, { from: accounts[1] });

      myShields = await pvpArena.getMyParticipatingShields({
        from: accounts[1],
      });

      expect(myShields.length).to.equal(0);
    });
  });

  describe("#reRollOpponent", () => {
    it("fails if character is not dueling", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      await createCharacterInPvpTier(accounts[2], 2);

      await expectRevert(
        pvpArena.reRollOpponent(character1ID, {
          from: accounts[1],
        }),
        "Character is not dueling"
      );
    });

    it("transfers skill from the sender to the contract", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      await createCharacterInPvpTier(accounts[2], 2);
      await createCharacterInPvpTier(accounts[3], 2);

      await time.increase(await pvpArena.unattackableSeconds());

      await pvpArena.requestOpponent(character1ID, {
        from: accounts[1],
      });

      const previousBalance = await skillToken.balanceOf(accounts[1]);

      await pvpArena.reRollOpponent(character1ID, {
        from: accounts[1],
      });

      const newBalance = await skillToken.balanceOf(accounts[1]);

      const duelCost = await pvpArena.getDuelCost(character1ID);

      const reRollPenalty = duelCost.div(toBN(4));

      expect(newBalance.toString()).to.equal(
        previousBalance.sub(reRollPenalty).toString()
      );
    });

    it("can not re roll the same opponent", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      await createCharacterInPvpTier(accounts[2], 2);

      await time.increase(await pvpArena.unattackableSeconds());

      await pvpArena.requestOpponent(character1ID, {
        from: accounts[1],
      });

      await expectRevert(
        pvpArena.reRollOpponent(character1ID, {
          from: accounts[1],
        }),
        "No opponent found"
      );
    });

    it("can re roll the same opponent if enough time has passed", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      const character2ID = await createCharacterInPvpTier(accounts[2], 2);

      await time.increase(await pvpArena.unattackableSeconds());

      await pvpArena.requestOpponent(character1ID, {
        from: accounts[1],
      });

      await time.increase(await pvpArena.unattackableSeconds());

      const { tx } = await pvpArena.reRollOpponent(character1ID, {
        from: accounts[1],
      });

      await expectEvent.inTransaction(tx, pvpArena, "NewDuel", {
        attacker: character1ID,
        defender: character2ID,
      });
    });

    it("assigns a new opponent", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      await createCharacterInPvpTier(accounts[2], 2);
      await createCharacterInPvpTier(accounts[3], 2);

      await time.increase(await pvpArena.unattackableSeconds());

      const requestOpponent = await pvpArena.requestOpponent(character1ID, {
        from: accounts[1],
      });

      const duelEvent = await expectEvent.inTransaction(
        requestOpponent.tx,
        pvpArena,
        "NewDuel"
      );

      const previouslyDueledPlayer = duelEvent.args.defender;

      let playerToDuelAfterReRoll;

      if (previouslyDueledPlayer === "1") {
        playerToDuelAfterReRoll = "2";
      } else {
        playerToDuelAfterReRoll = "1";
      }

      const reRoll = await pvpArena.reRollOpponent(character1ID, {
        from: accounts[1],
      });

      await expectEvent.inTransaction(reRoll.tx, pvpArena, "NewDuel", {
        attacker: character1ID,
        defender: playerToDuelAfterReRoll,
      });
    });
  });
});
