const web3 = require("web3");
const {
  expectRevert,
  expectEvent,
  time,
} = require("@openzeppelin/test-helpers");
const helpers = require("./helpers");

const { BN, toBN, fromWei } = web3.utils;

contract("PvpArena", (accounts) => {
  let pvpArena, characters, weapons, shields, priceOracle, randoms;

  async function createCharacterInPvpTier(
    account,
    tier,
    seed = "123",
    weaponID = null
  ) {
    const characterID = await helpers.createCharacter(account, seed, {
      characters,
    });

    let weaponIDToUse = weaponID;

    if (!weaponIDToUse) {
      weaponIDToUse = await helpers.createWeapon(account, seed, 0, {
        weapons,
      });
    }

    await helpers.levelUpTo(characterID, tier * 10, { characters });

    const cost = await pvpArena.getEntryWager(characterID, { from: account });

    await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
      from: account,
    });

    await pvpArena.enterArena(characterID, weaponIDToUse, 0, false, {
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
    await skillToken.transferFrom(
      skillToken.address,
      accounts[4],
      web3.utils.toWei("1", "kether")
    );

    await pvpArena.grantRole(await pvpArena.GAME_ADMIN(), accounts[0]);
    await characters.grantRole(await characters.GAME_ADMIN(), accounts[0]);
    await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[1]);
    await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[2]);
    await weapons.grantRole(await weapons.GAME_ADMIN(), accounts[0]);
    await shields.grantRole(await shields.GAME_ADMIN(), accounts[0]);
  });

  describe("#getDuelCost", () => {
    it("should return the correct cost", async () => {
      const charID = await createCharacterInPvpTier(accounts[1], 5, "888");
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
        const fighter = await pvpArena.fighterByCharacter(characterID);

        expect(isCharacterInArena).to.equal(true);
        expect(fighter.characterID.toString()).to.equal(
          toBN(characterID).toString()
        );
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
      it("should revert");
    });

    describe("weapon is in a raid", () => {
      it("should revert");
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

    describe("with pending duel", () => {
      let character0ID;

      beforeEach(async () => {
        character0ID = await createCharacterInPvpTier(accounts[1], 2, "000");
        character1ID = await createCharacterInPvpTier(accounts[2], 2, "111");
        character2ID = await createCharacterInPvpTier(accounts[2], 2, "222");

        await time.increase(await pvpArena.unattackableSeconds());
      });

      it("reverts", async () => {
        await pvpArena.requestOpponent(character0ID, { from: accounts[1] });
        await expectRevert(
          pvpArena.requestOpponent(character0ID, { from: accounts[1] }),
          "Opponent already requested"
        );
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
        const opponentID = await pvpArena.getOpponent(character0ID, {
          from: accounts[1],
        });

        await expectEvent.inTransaction(tx, pvpArena, "NewDuel", {
          attacker: character0ID,
          defender: character3ID,
        });

        expect(opponentID.toString()).to.equal(character3ID.toString());
      });

      it("should not consider characters owned by the sender", async () => {
        const character2ID = await createCharacterInPvpTier(accounts[1], 8);
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
      let character1ID;
      let character2ID;
      let duelTx;

      beforeEach(async () => {
        character1ID = await createCharacterInPvpTier(accounts[1], 4);
        character2ID = await createCharacterInPvpTier(accounts[2], 4);

        await time.increase(await pvpArena.unattackableSeconds());

        const { tx } = await pvpArena.requestOpponent(character1ID, {
          from: accounts[1],
        });

        duelTx = tx;
      });

      it("should emit the NewDuel event", async () => {
        await expectEvent.inTransaction(duelTx, pvpArena, "NewDuel", {
          attacker: character1ID,
          defender: character2ID,
        });
      });

      it("should put the attacker in an active duel", async () => {
        const isPending = await pvpArena.hasPendingDuel(character1ID, {
          from: accounts[1],
        });
        expect(isPending).to.equal(true);
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
      let myParticipatingCharacters =
        await pvpArena.getMyParticipatingCharacters({
          from: accounts[1],
        });

      let foundCharacter = myParticipatingCharacters.some((characterID) => {
        return characterID.toString() === character1ID.toString();
      });
      expect(foundCharacter).to.equal(true);

      await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

      myParticipatingCharacters = await pvpArena.getMyParticipatingCharacters({
        from: accounts[1],
      });

      foundCharacter = myParticipatingCharacters.some((characterID) => {
        return characterID.toString() === character1ID.toString();
      });

      expect(foundCharacter).to.equal(false);
      let isCharacterInArena = await pvpArena.isCharacterInArena(character1ID);
      expect(isCharacterInArena).to.equal(false);

      await pvpArena.withdrawFromArena(character2ID, { from: accounts[1] });

      myParticipatingCharacters = await pvpArena.getMyParticipatingCharacters({
        from: accounts[1],
      });

      expect(myParticipatingCharacters.length).to.equal(0);

      isCharacterInArena = await pvpArena.isCharacterInArena(character2ID);
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

    describe("with unclaimed earnings", async () => {
      describe("happy path", () => {
        let character1ID;
        let character2ID;
        let unclaimedEarnings;
        let wager;

        beforeEach(async () => {
          const weapon1ID = await helpers.createWeapon(
            accounts[1],
            "111",
            helpers.elements.water,
            {
              weapons,
            }
          );
          const weapon2ID = await helpers.createWeapon(
            accounts[2],
            "111",
            helpers.elements.fire,
            {
              weapons,
            }
          );

          character1ID = await createCharacterInPvpTier(
            accounts[1],
            2,
            "222",
            weapon1ID
          );
          character2ID = await createCharacterInPvpTier(
            accounts[2],
            2,
            "222",
            weapon2ID
          );

          await characters.setTrait(character1ID, helpers.elements.water, {
            from: accounts[0],
          });
          await characters.setTrait(character2ID, helpers.elements.fire, {
            from: accounts[0],
          });

          await time.increase(await pvpArena.unattackableSeconds());
          await pvpArena.requestOpponent(character1ID, {
            from: accounts[1],
          });
          await pvpArena.performDuel(character1ID, {
            from: accounts[1],
          });
          wager = await pvpArena.getCharacterWager(character1ID);
          unclaimedEarnings = await pvpArena.getUnclaimedDuelEarnings(
            character1ID,
            {
              from: accounts[1],
            }
          );
        });

        it("should pay the owner the character's earnings", async () => {
          const previousBalance = await skillToken.balanceOf(accounts[1]);
          await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

          const newUnclaimedEarnings = await pvpArena.getUnclaimedDuelEarnings(
            character1ID,
            {
              from: accounts[1],
            }
          );

          const balance = await skillToken.balanceOf(accounts[1]);

          expect(newUnclaimedEarnings.toString()).to.equal(toBN(0).toString());

          expect(balance.toString()).to.equal(
            toBN(unclaimedEarnings).add(previousBalance).add(wager).toString()
          );
        });
      });

      describe("with pending duel", () => {
        let character1ID;
        let character2ID;
        let unclaimedEarnings;
        let wager;

        beforeEach(async () => {
          const weapon1ID = await helpers.createWeapon(
            accounts[1],
            "111",
            helpers.elements.water,
            {
              weapons,
            }
          );
          const weapon2ID = await helpers.createWeapon(
            accounts[2],
            "111",
            helpers.elements.fire,
            {
              weapons,
            }
          );

          character1ID = await createCharacterInPvpTier(
            accounts[1],
            2,
            "222",
            weapon1ID
          );
          character2ID = await createCharacterInPvpTier(
            accounts[2],
            2,
            "222",
            weapon2ID
          );

          await characters.setTrait(character1ID, helpers.elements.water, {
            from: accounts[0],
          });
          await characters.setTrait(character2ID, helpers.elements.fire, {
            from: accounts[0],
          });

          await time.increase(await pvpArena.unattackableSeconds());
          await pvpArena.requestOpponent(character1ID, {
            from: accounts[1],
          });
          await pvpArena.performDuel(character1ID, {
            from: accounts[1],
          });
          wager = await pvpArena.getCharacterWager(character1ID);
          unclaimedEarnings = await pvpArena.getUnclaimedDuelEarnings(
            character1ID,
            {
              from: accounts[1],
            }
          );

          await time.increase(await pvpArena.unattackableSeconds());

          await pvpArena.requestOpponent(character1ID, {
            from: accounts[1],
          });
        });

        it("should return unclaimed earnings minus the penalty from the refunded amount", async () => {
          const previousBalance = await skillToken.balanceOf(accounts[1]);
          await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

          const newUnclaimedEarnings = await pvpArena.getUnclaimedDuelEarnings(
            character1ID,
            {
              from: accounts[1],
            }
          );

          const balance = await skillToken.balanceOf(accounts[1]);

          expect(newUnclaimedEarnings.toString()).to.equal(toBN(0).toString());

          expect(balance.toString()).to.equal(
            toBN(unclaimedEarnings)
              .add(previousBalance)
              .add(wager.sub(wager.div(toBN(4))))
              .toString()
          );
        });

        it("should reset the character's duel", async () => {
          await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

          const hasPendingDuel = await pvpArena.hasPendingDuel(character1ID);

          expect(hasPendingDuel).to.equal(false);
        });
      });
    });

    describe("decision time expired", () => {
      it("should subtract the penalty from the refunded amount");
    });
  });

  describe("#performDuel", async () => {
    describe("happy path", () => {
      describe("attacker wins", () => {
        let character1ID;
        let character2ID;
        let character1Wager;
        let character2Wager;
        let duelEvent;
        let bounty;
        let poolTax;
        let winnerReward;

        beforeEach(async () => {
          // We create 2 identical characters with identical weapons, then
          // we make 1 effective against the other so that the result is always
          // the same
          const weapon1ID = await helpers.createWeapon(
            accounts[1],
            "111",
            helpers.elements.water,
            {
              weapons,
            }
          );
          const weapon2ID = await helpers.createWeapon(
            accounts[2],
            "111",
            helpers.elements.fire,
            {
              weapons,
            }
          );

          character1ID = await createCharacterInPvpTier(
            accounts[1],
            2,
            "222",
            weapon1ID
          );
          character2ID = await createCharacterInPvpTier(
            accounts[2],
            2,
            "222",
            weapon2ID
          );

          await characters.setTrait(character1ID, helpers.elements.water, {
            from: accounts[0],
          });
          await characters.setTrait(character2ID, helpers.elements.fire, {
            from: accounts[0],
          });

          await time.increase(await pvpArena.unattackableSeconds());
          await pvpArena.requestOpponent(character1ID, {
            from: accounts[1],
          });

          character1Wager = await pvpArena.getCharacterWager(character1ID, {
            from: accounts[1],
          });
          character2Wager = await pvpArena.getCharacterWager(character2ID, {
            from: accounts[2],
          });

          const { tx } = await pvpArena.performDuel(character1ID, {
            from: accounts[1],
          });
          previousBalance = await skillToken.balanceOf(accounts[1]);
          duelEvent = await expectEvent.inTransaction(
            tx,
            pvpArena,
            "DuelFinished"
          );

          duelTx = tx;
          duelCost = await pvpArena.getDuelCost(character1ID, {
            from: accounts[1],
          });

          bounty = duelCost.mul(toBN(2));
          poolTax = bounty.mul(toBN(15)).div(toBN(100));
          winnerReward = bounty.sub(poolTax).sub(duelCost);
        });

        it("should add to the winner's earnings balance", async () => {
          const unclaimedEarnings = await pvpArena.getUnclaimedDuelEarnings(
            character1ID,
            {
              from: accounts[1],
            }
          );

          expect(unclaimedEarnings.toString()).to.equal(
            winnerReward.toString()
          );
        });

        it("should remove the duel cost from the loser's wager", async () => {
          const character2NewWager = await pvpArena.getCharacterWager(
            character2ID,
            {
              from: accounts[2],
            }
          );

          // should remove battleCost from the defender's wager
          expect(character2NewWager.toString()).to.equal(
            character2Wager.sub(duelCost).toString()
          );
        });

        it("should not change attacker's wager", async () => {
          const character1NewWager = await pvpArena.getCharacterWager(
            character1ID,
            {
              from: accounts[1],
            }
          );

          expect(character1NewWager.toString()).to.equal(
            character1Wager.toString()
          );
        });

        it("should save the ranking prize pool", async () => {
          const tier = await pvpArena.getArenaTier(character1ID, {
            from: accounts[1],
          });
          const rewardsInPool = await pvpArena.getRankingRewardsPool(tier, {
            from: accounts[1],
          });

          expect(rewardsInPool.toString()).to.equal(poolTax.toString());
        });

        it("should emit the DuelFinished event", async () => {
          await expectEvent.inTransaction(duelTx, pvpArena, "DuelFinished");
        });

        it("should mark the attacker as no longer in an active duel", async () => {
          const isPending = await pvpArena.hasPendingDuel(character1ID, {
            from: accounts[1],
          });

          expect(isPending).to.equal(false);
        });
      });

      describe("attacker is effective against defender", () => {
        let character1ID;
        let character2ID;
        let weapon1ID;
        let weapon2ID;
        let duelTx;

        beforeEach(async () => {
          weapon1ID = await helpers.createWeapon(
            accounts[1],
            "111",
            helpers.elements.water,
            {
              weapons,
            }
          );
          weapon2ID = await helpers.createWeapon(
            accounts[2],
            "111",
            helpers.elements.fire,
            {
              weapons,
            }
          );

          character1ID = await createCharacterInPvpTier(
            accounts[1],
            2,
            "222",
            weapon1ID
          );
          character2ID = await createCharacterInPvpTier(
            accounts[2],
            2,
            "222",
            weapon2ID
          );

          await characters.setTrait(character1ID, helpers.elements.water, {
            from: accounts[0],
          });
          await characters.setTrait(character2ID, helpers.elements.fire, {
            from: accounts[0],
          });

          await time.increase(await pvpArena.unattackableSeconds());
          await pvpArena.requestOpponent(character1ID, {
            from: accounts[1],
          });

          const { tx } = await pvpArena.performDuel(character1ID, {
            from: accounts[1],
          });
          duelTx = tx;
        });

        it("should apply bonus to the attacker", async () => {
          const duelEvent = await expectEvent.inTransaction(
            duelTx,
            pvpArena,
            "DuelFinished"
          );

          expect(Number(duelEvent.args.attackerRoll)).to.be.gt(
            Number(duelEvent.args.defenderRoll)
          );
        });
      });

      describe("attacker loses", () => {
        let character1ID;
        let character2ID;
        let character1Wager;
        let character2Wager;
        let weapon1ID;
        let weapon2ID;
        let bounty;
        let poolTax;
        let winnerReward;

        beforeEach(async () => {
          weapon1ID = await helpers.createWeapon(
            accounts[1],
            "111",
            helpers.elements.fire,
            {
              weapons,
            }
          );
          weapon2ID = await helpers.createWeapon(
            accounts[2],
            "111",
            helpers.elements.water,
            {
              weapons,
            }
          );

          character1ID = await createCharacterInPvpTier(
            accounts[1],
            2,
            "222",
            weapon1ID
          );
          character2ID = await createCharacterInPvpTier(
            accounts[2],
            2,
            "222",
            weapon2ID
          );
          const duelCost = await pvpArena.getDuelCost(character1ID, {
            from: accounts[1],
          });

          await characters.setTrait(character1ID, helpers.elements.fire, {
            from: accounts[0],
          });
          await characters.setTrait(character2ID, helpers.elements.water, {
            from: accounts[0],
          });

          character1Wager = await pvpArena.getCharacterWager(character1ID, {
            from: accounts[1],
          });
          character2Wager = await pvpArena.getCharacterWager(character2ID, {
            from: accounts[2],
          });

          await time.increase(await pvpArena.unattackableSeconds());
          await pvpArena.requestOpponent(character1ID, {
            from: accounts[1],
          });

          const { tx } = await pvpArena.performDuel(character1ID, {
            from: accounts[1],
          });

          duelTx = tx;
          bounty = duelCost.mul(toBN(2));
          poolTax = bounty.mul(toBN(15)).div(toBN(100));
          winnerReward = bounty.sub(poolTax).sub(duelCost);
        });

        it("should pay the defender their prize", async () => {
          const unclaimedEarnings = await pvpArena.getUnclaimedDuelEarnings(
            character2ID,
            {
              from: accounts[2],
            }
          );

          expect(unclaimedEarnings.toString()).to.equal(
            winnerReward.toString()
          );
        });

        it("should remove the duel cost from the attacker's wager", async () => {
          const character1NewWager = await pvpArena.getCharacterWager(
            character1ID,
            {
              from: accounts[1],
            }
          );

          expect(character1NewWager.toString()).to.equal(
            character1Wager.sub(toBN(duelCost)).toString()
          );
        });
      });
    });
    describe("decision time expired", () => {
      let characterID;

      beforeEach(async () => {
        characterID = await createCharacterInPvpTier(accounts[1], 2, "222");
        await createCharacterInPvpTier(accounts[2], 2, "222");

        await time.increase(await pvpArena.unattackableSeconds());
        await pvpArena.requestOpponent(characterID, {
          from: accounts[1],
        });

        const decisionSeconds = await pvpArena.decisionSeconds();
        await time.increase(decisionSeconds);
      });

      it("should revert", async () => {
        await expectRevert(
          pvpArena.performDuel(characterID, {
            from: accounts[1],
          }),
          "Decision time expired"
        );
      });
    });

    describe("character not in a duel", () => {
      let characterID;
      beforeEach(async () => {
        characterID = await createCharacterInPvpTier(accounts[1], 2, "222");
      });

      it("should revert", async () => {
        await expectRevert(
          pvpArena.performDuel(characterID, {
            from: accounts[1],
          }),
          "Character not in a duel"
        );
      });
    });

    describe("character is not the sender's", () => {
      let characterID;
      beforeEach(async () => {
        characterID = await createCharacterInPvpTier(accounts[1], 2, "222");
      });

      it("should revert", async () => {
        await expectRevert(
          pvpArena.performDuel(characterID, {
            from: accounts[2],
          }),
          "Character is not owned by sender"
        );
      });
    });

    describe("#reRollOpponent", () => {
      it("should fail if character is not dueling", async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 2);
        await createCharacterInPvpTier(accounts[2], 2);

        await expectRevert(
          pvpArena.reRollOpponent(character1ID, {
            from: accounts[1],
          }),
          "Character is not dueling"
        );
      });

      it("should transfer skill from the sender to the contract", async () => {
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

      it("should not re roll the same opponent", async () => {
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

      it("should re roll the same opponent if enough time has passed", async () => {
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

      it("should assign a new opponent", async () => {
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

  describe("#getOpponent", () => {
    describe("with pending duel", () => {
      let character0ID;
      let character1ID;

      beforeEach(async () => {
        character0ID = await createCharacterInPvpTier(accounts[1], 1);
        character1ID = await createCharacterInPvpTier(accounts[2], 1);

        await time.increase(await pvpArena.unattackableSeconds());

        await pvpArena.requestOpponent(character0ID, {
          from: accounts[1],
        });
      });

      it("should return the opponent", async () => {
        const opponentID = await pvpArena.getOpponent(character0ID);
      });
    });

    describe("without pending duel", () => {
      let characterID;

      beforeEach(async () => {
        characterID = await createCharacterInPvpTier(accounts[1], 1);
      });

      it("should revert", async () => {
        expectRevert(
          pvpArena.getOpponent(characterID),
          "Character has no pending duel"
        );
      });
    });
  });

  describe("#getUnclaimedDuelEarnings", () => {
    let character1ID;
    let character2ID;

    beforeEach(async () => {
      const weapon1ID = await helpers.createWeapon(
        accounts[1],
        "111",
        helpers.elements.water,
        { weapons }
      );
      const weapon2ID = await helpers.createWeapon(
        accounts[2],
        "111",
        helpers.elements.fire,
        { weapons }
      );

      character1ID = await createCharacterInPvpTier(
        accounts[1],
        1,
        "999",
        weapon1ID
      );
      character2ID = await createCharacterInPvpTier(
        accounts[2],
        1,
        "999",
        weapon2ID
      );

      await characters.setTrait(character1ID, helpers.elements.water, {
        from: accounts[0],
      });
      await characters.setTrait(character2ID, helpers.elements.fire, {
        from: accounts[0],
      });

      await time.increase(await pvpArena.unattackableSeconds());

      await pvpArena.requestOpponent(character1ID, { from: accounts[1] });

      await pvpArena.performDuel(character1ID, { from: accounts[1] });
    });

    it("should return the character's unclaimed earnings", async () => {
      const earnings = await pvpArena.getUnclaimedDuelEarnings(character1ID, {
        from: accounts[1],
      });

      const duelCost = await pvpArena.getDuelCost(character1ID);
      const bounty = duelCost.mul(toBN(2));
      const poolTax = bounty.mul(toBN(15)).div(toBN(100));
      const winnerReward = bounty.sub(poolTax).sub(duelCost);

      expect(earnings.toString()).to.equal(winnerReward.toString());
    });
  });

  describe("#getAllUnclaimedDuelEarnings", () => {
    let character1ID;
    beforeEach(async () => {
      const weapon1ID = await helpers.createWeapon(
        accounts[1],
        "111",
        helpers.elements.water,
        { weapons }
      );
      const weapon2ID = await helpers.createWeapon(
        accounts[1],
        "111",
        helpers.elements.water,
        { weapons }
      );
      const weapon3ID = await helpers.createWeapon(
        accounts[2],
        "111",
        helpers.elements.fire,
        { weapons }
      );

      character1ID = await createCharacterInPvpTier(
        accounts[1],
        1,
        "999",
        weapon1ID
      );
      const character2ID = await createCharacterInPvpTier(
        accounts[1],
        1,
        "999",
        weapon2ID
      );
      const character3ID = await createCharacterInPvpTier(
        accounts[2],
        1,
        "999",
        weapon3ID
      );

      await characters.setTrait(character1ID, helpers.elements.water, {
        from: accounts[0],
      });
      await characters.setTrait(character2ID, helpers.elements.water, {
        from: accounts[0],
      });
      await characters.setTrait(character3ID, helpers.elements.fire, {
        from: accounts[0],
      });

      await time.increase(await pvpArena.unattackableSeconds());

      await pvpArena.requestOpponent(character1ID, { from: accounts[1] });
      await pvpArena.performDuel(character1ID, { from: accounts[1] });

      await time.increase(await pvpArena.unattackableSeconds());

      await pvpArena.requestOpponent(character2ID, { from: accounts[1] });
      await pvpArena.performDuel(character2ID, { from: accounts[1] });
    });

    it("should return the sum off all unclaimed earnings of the sender's fighters", async () => {
      const totalEarnings = await pvpArena.getAllUnclaimedDuelEarnings({
        from: accounts[1],
      });
      const duelCost = await pvpArena.getDuelCost(character1ID);
      const bounty = duelCost.mul(toBN(2));
      const poolTax = bounty.mul(toBN(15)).div(toBN(100));
      const winnerReward = bounty.sub(poolTax).sub(duelCost);

      expect(totalEarnings.toString()).to.equal(
        winnerReward.mul(toBN(2)).toString()
      );
    });
  });

  describe("#withdrawDuelEarnings", () => {
    describe("with unclaimed earnings", () => {
      let character1ID;
      let earnings;
      let balance;

      beforeEach(async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "111",
          helpers.elements.water,
          { weapons }
        );
        const weapon2ID = await helpers.createWeapon(
          accounts[1],
          "111",
          helpers.elements.water,
          { weapons }
        );
        const weapon3ID = await helpers.createWeapon(
          accounts[2],
          "111",
          helpers.elements.fire,
          { weapons }
        );

        character1ID = await createCharacterInPvpTier(
          accounts[1],
          1,
          "999",
          weapon1ID
        );
        const character2ID = await createCharacterInPvpTier(
          accounts[1],
          1,
          "999",
          weapon2ID
        );
        const character3ID = await createCharacterInPvpTier(
          accounts[2],
          1,
          "999",
          weapon3ID
        );

        await characters.setTrait(character1ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character2ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character3ID, helpers.elements.fire, {
          from: accounts[0],
        });

        await time.increase(await pvpArena.unattackableSeconds());

        await pvpArena.requestOpponent(character1ID, { from: accounts[1] });
        await pvpArena.performDuel(character1ID, { from: accounts[1] });

        await time.increase(await pvpArena.unattackableSeconds());

        await pvpArena.requestOpponent(character1ID, { from: accounts[1] });
        await pvpArena.performDuel(character1ID, { from: accounts[1] });

        earnings = pvpArena.getUnclaimedDuelEarnings(character1ID, {
          from: accounts[1],
        });

        balance = await skillToken.balanceOf(accounts[1]);
      });

      it("should send the unclaimed earnings to the sender", async () => {
        await pvpArena.withdrawDuelEarnings(character1ID, {
          from: accounts[1],
        });

        const newBalance = await skillToken.balanceOf(accounts[1]);
        const duelCost = await pvpArena.getDuelCost(character1ID);
        const bounty = duelCost.mul(toBN(2));
        const poolTax = bounty.mul(toBN(15)).div(toBN(100));
        const winnerReward = bounty.sub(poolTax).sub(duelCost);

        expect(newBalance.toString()).to.equal(
          balance.add(winnerReward.mul(toBN(2))).toString()
        );
      });

      it("should reset unclaimed earnings of the character", async () => {
        await pvpArena.withdrawDuelEarnings(character1ID, {
          from: accounts[1],
        });
        const newEarnings = await pvpArena.getUnclaimedDuelEarnings(
          character1ID,
          {
            from: accounts[1],
          }
        );

        expect(newEarnings.toString()).to.equal(toBN(0).toString());
      });
    });

    describe("without unclaimed earnings", () => {
      let characterID;

      beforeEach(async () => {
        characterID = await createCharacterInPvpTier(accounts[1], 1, "111");
      });

      it("should revert", async () => {
        await expectRevert(
          pvpArena.withdrawDuelEarnings(characterID, {
            from: accounts[1],
          }),
          "No unclaimed earnings"
        );
      });
    });
  });

  describe("#withdrawAllDuelEarnings", () => {
    describe("with unclaimed earnings", () => {
      beforeEach(async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "111",
          helpers.elements.water,
          { weapons }
        );
        const weapon2ID = await helpers.createWeapon(
          accounts[1],
          "111",
          helpers.elements.water,
          { weapons }
        );
        const weapon3ID = await helpers.createWeapon(
          accounts[2],
          "111",
          helpers.elements.fire,
          { weapons }
        );

        const character1ID = await createCharacterInPvpTier(
          accounts[1],
          1,
          "999",
          weapon1ID
        );
        const character2ID = await createCharacterInPvpTier(
          accounts[1],
          1,
          "999",
          weapon2ID
        );
        const character3ID = await createCharacterInPvpTier(
          accounts[2],
          1,
          "999",
          weapon3ID
        );

        await characters.setTrait(character1ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character2ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character3ID, helpers.elements.fire, {
          from: accounts[0],
        });

        await time.increase(await pvpArena.unattackableSeconds());

        await pvpArena.requestOpponent(character1ID, { from: accounts[1] });
        await pvpArena.performDuel(character1ID, { from: accounts[1] });

        await time.increase(await pvpArena.unattackableSeconds());

        await pvpArena.requestOpponent(character2ID, { from: accounts[1] });
        await pvpArena.performDuel(character2ID, { from: accounts[1] });
      });

      it("should transfer the sum of all unclaimed earnings to the sender", async () => {
        const balance = await skillToken.balanceOf(accounts[1]);

        const earnings = await pvpArena.getAllUnclaimedDuelEarnings({
          from: accounts[1],
        });

        await pvpArena.withdrawAllDuelEarnings({
          from: accounts[1],
        });

        const newBalance = await skillToken.balanceOf(accounts[1]);

        expect(newBalance.toString()).to.equal(
          balance.add(earnings).toString()
        );
      });

      it("should set all unclaimed earnings to 0", async () => {
        await pvpArena.withdrawAllDuelEarnings({
          from: accounts[1],
        });
        const newEarnings = await pvpArena.getAllUnclaimedDuelEarnings({
          from: accounts[1],
        });
        expect(newEarnings.toString()).to.equal(toBN(0).toString());
      });
    });

    describe("without unclaimed earnings", () => {
      it("should revert", async () => {
        await expectRevert(
          pvpArena.withdrawAllDuelEarnings({
            from: accounts[1],
          }),
          "No unclaimed earnings"
        );
      });
    });
  });

  describe("rankingBehaviour", () => {
    describe("entering the arena ", () => {
      let character1ID;
      let character2ID;
      let character3ID;
      let character4ID;
      let character5ID;
      let character6ID;
      let weapon1ID;
      let weapon2ID;

      it("should fill the rank with the first 4 players", async () => {
        character1ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        character2ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        character3ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        //this char will be in a different tier
        character4ID = await createCharacterInPvpTier(accounts[2], 3, "222");
        character5ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character6ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        const characterTier = await pvpArena.getTopTierPlayers(character1ID, {
          from: accounts[1],
        });

        expect(characterTier[0].toString()).to.equal(character1ID.toString());
        expect(characterTier[3].toString()).to.equal(character5ID.toString());
      });
    });

    describe("after the fight", () => {
      it("update the ranks of both the winner and the loser and add/subtract points respectively", async () => {
        const winningPoints = await pvpArena.winningPoints();
        const losingPoints = await pvpArena.losingPoints();
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "111",
          helpers.elements.water,
          {
            weapons,
          }
        );
        weapon2ID = await helpers.createWeapon(
          accounts[1],
          "111",
          helpers.elements.fire,
          {
            weapons,
          }
        );
        character1ID = await createCharacterInPvpTier(
          accounts[1],
          2,
          "222",
          weapon2ID
        );
        character2ID = await createCharacterInPvpTier(accounts[2], 2);
        character3ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character4ID = await createCharacterInPvpTier(
          accounts[2],
          2,
          "222",
          weapon1ID
        );

        await characters.setTrait(character4ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character1ID, helpers.elements.fire, {
          from: accounts[0],
        });
        // we set the ranking points to determine the tier, char2 being the first, followed by char 1 and then char3
        await pvpArena.setRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character2ID, 34, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character3ID, 33, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character4ID, 32, {
          from: accounts[0],
        });

        const winnerPreviousRankPoints =
          await pvpArena.getCharacterRankingPoints(character4ID);
        const loserPreviousRankPoints =
          await pvpArena.getCharacterRankingPoints(character1ID);

        await time.increase(await pvpArena.unattackableSeconds());
        await pvpArena.requestOpponent(character4ID, {
          from: accounts[2],
        });

        // perform a duel making sure character4 is always going to win
        await pvpArena.performDuel(character4ID, {
          from: accounts[2],
        });

        const winnerPostRankPoints = await pvpArena.getCharacterRankingPoints(
          character4ID
        );
        const loserPostRankPoints = await pvpArena.getCharacterRankingPoints(
          character1ID
        );

        // get the post  duel ranking points
        const playerTier = await pvpArena.getTopTierPlayers(character1ID, {
          from: accounts[1],
        });
        // expect the last player to be the first
        expect(playerTier[0].toString()).to.equal(character4ID.toString());
        expect(playerTier[3].toString()).to.equal(character1ID.toString());
        // expect to add and subtract ranking points respectively
        expect(winnerPostRankPoints.toString()).to.equal(
          winnerPreviousRankPoints.add(winningPoints).toString()
        );
        expect(loserPostRankPoints.toString()).to.equal(
          loserPreviousRankPoints.sub(losingPoints).toString()
        );
      });

      it("should update the player if he is not within the top 4 and has a higher score than the 4th ranked player", async () => {
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "111",
          helpers.elements.water,
          {
            weapons,
          }
        );
        weapon2ID = await helpers.createWeapon(
          accounts[1],
          "111",
          helpers.elements.fire,
          {
            weapons,
          }
        );
        character1ID = await createCharacterInPvpTier(
          accounts[1],
          2,
          "222",
          weapon2ID
        );
        character2ID = await createCharacterInPvpTier(accounts[2], 2);
        character3ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character4ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character5ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character6ID = await createCharacterInPvpTier(
          accounts[2],
          2,
          "222",
          weapon1ID
        );

        await characters.setTrait(character6ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character1ID, helpers.elements.fire, {
          from: accounts[0],
        });

        await pvpArena.setRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character2ID, 34, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character3ID, 33, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character4ID, 32, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character5ID, 31, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character6ID, 30, {
          from: accounts[0],
        });
        await time.increase(await pvpArena.unattackableSeconds());
        await pvpArena.requestOpponent(character6ID, {
          from: accounts[2],
        });

        // perform a duel making sure character6 is always going to win
        await pvpArena.performDuel(character6ID, {
          from: accounts[2],
        });
        const playerTier = await pvpArena.getTopTierPlayers(character1ID);
        // expect the last character to be the first one, climibing through the entire ladder
        expect(playerTier[0].toString()).to.equal(character6ID).toString();
      });

      it("should process the winner and the loser with only 2 players inside the tier", async () => {
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "111",
          helpers.elements.water,
          {
            weapons,
          }
        );
        weapon2ID = await helpers.createWeapon(
          accounts[1],
          "111",
          helpers.elements.fire,
          {
            weapons,
          }
        );
        character1ID = await createCharacterInPvpTier(
          accounts[1],
          2,
          "222",
          weapon2ID
        );
        character2ID = await createCharacterInPvpTier(
          accounts[2],
          2,
          "222",
          weapon1ID
        );
        await characters.setTrait(character2ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character1ID, helpers.elements.fire, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character1ID, 15, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character2ID, 13, {
          from: accounts[0],
        });

        await time.increase(await pvpArena.unattackableSeconds());
        await pvpArena.requestOpponent(character2ID, {
          from: accounts[2],
        });

        // perform a duel making sure character1 is always going to lose, meaning character 2 will be the top 1
        await pvpArena.performDuel(character2ID, {
          from: accounts[2],
        });

        const playerTier = await pvpArena.getTopTierPlayers(character1ID);

        expect(playerTier[0].toString()).to.equal(character2ID).toString();
        expect(playerTier[1].toString()).to.equal(character1ID).toString();
        expect(playerTier[2]).to.equal(undefined);
      });
    });
    describe("loser path", () => {
      it("should not update the ranks if the loser is not within the top 4", async () => {
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "111",
          helpers.elements.water,
          {
            weapons,
          }
        );
        weapon2ID = await helpers.createWeapon(
          accounts[1],
          "111",
          helpers.elements.fire,
          {
            weapons,
          }
        );
        character1ID = await createCharacterInPvpTier(
          accounts[1],
          2,
          "222",
          weapon2ID
        );
        character2ID = await createCharacterInPvpTier(accounts[2], 2);
        character3ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character4ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character5ID = await createCharacterInPvpTier(
          accounts[2],
          2,
          "222",
          weapon1ID
        );

        await characters.setTrait(character5ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character1ID, helpers.elements.fire, {
          from: accounts[0],
        });
        // we set the ranking points to determine the tier, char1 being the first, followed by char 2 and then char4
        await pvpArena.setRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character2ID, 34, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character3ID, 33, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character4ID, 32, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character5ID, 10, {
          from: accounts[0],
        });

        await time.increase(await pvpArena.unattackableSeconds());
        await pvpArena.requestOpponent(character5ID, {
          from: accounts[2],
        });
        // perform a duel making sure character1 is always going to lose
        await pvpArena.performDuel(character5ID, {
          from: accounts[2],
        });

        // get the post  duel ranking points
        const playerTier = await pvpArena.getTopTierPlayers(character1ID, {
          from: accounts[1],
        });

        const isCharacterInTier = playerTier.some((player) => {
          player.toString() === character5ID.toString();
        });
        //expect loser player to remain in the same spot
        expect(isCharacterInTier).to.equal(false);
        expect(playerTier[3].toString()).to.equal(character1ID.toString());
      });
    });
  });

  describe("#distributeSeasonRewards", () => {
    // These tests assume prizes will be distributed amongst at least 2 players and at most 4 players.
    beforeEach(async () => {
      character1ID = await createCharacterInPvpTier(accounts[1], 1);
      character2ID = await createCharacterInPvpTier(accounts[2], 1);

      await pvpArena.setRankingPoints(character1ID, 100, {
        from: accounts[0],
      });
      await pvpArena.setRankingPoints(character2ID, 80, {
        from: accounts[0],
      });

      await time.increase(await pvpArena.unattackableSeconds());

      // We execute a duel so theres a prize pool
      await pvpArena.requestOpponent(character1ID, {
        from: accounts[1],
      });

      await pvpArena.performDuel(character1ID, {
        from: accounts[1],
      });
    });

    it("distributes rewards correctly to top characters' owners", async () => {
      const prizePercentages = await pvpArena.getPrizePercentages();

      const character3ID = await createCharacterInPvpTier(accounts[3], 1);
      const character4ID = await createCharacterInPvpTier(accounts[4], 1);

      await pvpArena.setRankingPoints(character3ID, 60, {
        from: accounts[0],
      });
      await pvpArena.setRankingPoints(character4ID, 40, {
        from: accounts[0],
      });

      const balanceOne = await skillToken.balanceOf(accounts[1]);
      const balanceTwo = await skillToken.balanceOf(accounts[2]);
      const balanceThree = await skillToken.balanceOf(accounts[3]);
      const balanceFour = await skillToken.balanceOf(accounts[4]);

      await pvpArena.distributeSeasonRewards({ from: accounts[0] });

      await pvpArena.withdrawRankedRewards({ from: accounts[1] });
      await pvpArena.withdrawRankedRewards({ from: accounts[2] });
      await pvpArena.withdrawRankedRewards({ from: accounts[3] });
      await pvpArena.withdrawRankedRewards({ from: accounts[4] });

      const newBalanceOne = await skillToken.balanceOf(accounts[1]);
      const newBalanceTwo = await skillToken.balanceOf(accounts[2]);
      const newBalanceThree = await skillToken.balanceOf(accounts[3]);
      const newBalanceFour = await skillToken.balanceOf(accounts[4]);

      const expectedPlayerOneWithdrawal = newBalanceOne.sub(balanceOne);
      const expectedPlayerTwoWithdrawal = newBalanceTwo.sub(balanceTwo);
      const expectedPlayerThreeWithdrawal = newBalanceThree.sub(balanceThree);
      const expectedPlayerFourWithdrawal = newBalanceFour.sub(balanceFour);

      const totalPool = expectedPlayerOneWithdrawal
        .add(expectedPlayerTwoWithdrawal)
        .add(expectedPlayerThreeWithdrawal)
        .add(expectedPlayerFourWithdrawal);

      const isNewBalanceOneValid =
        newBalanceOne.toString() ===
        balanceOne
          .add(totalPool.div(toBN(100)).mul(prizePercentages[0]))
          .toString();

      const isNewBalanceTwoValid =
        newBalanceTwo.toString() ===
        balanceTwo
          .add(totalPool.div(toBN(100)).mul(prizePercentages[1]))
          .toString();

      expect(isNewBalanceOneValid).to.equal(true);
      expect(isNewBalanceTwoValid).to.equal(true);

      if (prizePercentages.length > 2) {
        const isNewBalanceThreeValid =
          newBalanceThree.toString() ===
          balanceThree
            .add(totalPool.div(toBN(100)).mul(prizePercentages[2]))
            .toString();

        expect(isNewBalanceThreeValid).to.equal(true);
      }
      if (prizePercentages.length > 3) {
        const isNewBalanceFourValid =
          newBalanceFour.toString() ===
          balanceFour
            .add(totalPool.div(toBN(100)).mul(prizePercentages[3]))
            .toString();

        expect(isNewBalanceFourValid).to.equal(true);
      }
    });

    it("gives excess rewards to top 1 player if there are less players than the amount of top slots", async () => {
      const prizePercentages = await pvpArena.getPrizePercentages();

      const balanceOne = await skillToken.balanceOf(accounts[1]);
      const balanceTwo = await skillToken.balanceOf(accounts[2]);

      await pvpArena.distributeSeasonRewards({ from: accounts[0] });

      await pvpArena.withdrawRankedRewards({ from: accounts[1] });
      await pvpArena.withdrawRankedRewards({ from: accounts[2] });

      const newBalanceOne = await skillToken.balanceOf(accounts[1]);
      const newBalanceTwo = await skillToken.balanceOf(accounts[2]);

      const expectedPlayerOneWithdrawal = newBalanceOne.sub(balanceOne);
      const expectedPlayerTwoWithdrawal = newBalanceTwo.sub(balanceTwo);

      const totalPool = expectedPlayerOneWithdrawal.add(
        expectedPlayerTwoWithdrawal
      );

      let excessPrizePercentage = 0;

      for (let i = 2; i < prizePercentages.length; i++) {
        excessPrizePercentage = +excessPrizePercentage + +prizePercentages[i];
      }

      const isNewBalanceOneValid =
        newBalanceOne.toString() ===
        balanceOne
          .add(
            totalPool
              .div(toBN(100))
              .mul(prizePercentages[0].add(toBN(excessPrizePercentage)))
          )
          .toString();

      const isNewBalanceTwoValid =
        newBalanceTwo.toString() ===
        balanceTwo
          .add(totalPool.div(toBN(100)).mul(prizePercentages[1]))
          .toString();

      expect(isNewBalanceOneValid).to.equal(true);
      expect(isNewBalanceTwoValid).to.equal(true);
    });
  });
});
