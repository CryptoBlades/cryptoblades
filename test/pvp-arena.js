const {
  expectRevert,
  expectEvent,
  time,
} = require("@openzeppelin/test-helpers");
const helpers = require("./helpers");

const { BN, toBN, fromWei } = web3.utils;

contract("PvpArena", (accounts) => {
  let pvpArena, characters, weapons, shields, priceOracle, randoms, raid1;

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
    raid1 = contracts.raid1;

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
    await raid1.grantRole(await raid1.GAME_ADMIN(), accounts[0]);
    
    await pvpArena.setArenaAccess(1, { from: accounts[0] });
    await pvpArena.setPvpBotAddress(accounts[10], { from: accounts[0] });
  });

  describe("#getDuelCost", () => {
    it("should return the correct cost", async () => {
      const charID = await createCharacterInPvpTier(accounts[1], 5, "888");
      const cost = await pvpArena.getDuelCost(charID, { from: accounts[1] });

      expect(cost.toString()).to.be.equal(web3.utils.toWei("7.5"));
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

      it("should place character in current season if it had never entered PVP before", async () => {
        const currentSeason = (await pvpArena.currentRankedSeason()).toString();

        character1ID = await createCharacterInPvpTier(accounts[1], 2);

        expect(
          (await pvpArena.seasonByCharacter(character1ID)).toString()
        ).to.equal(currentSeason);
      });

      it("should reset character's rank if it changes tier", async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "101",
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

        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

        let duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        expect(
          (
            await pvpArena.rankingPointsByCharacter(character1ID, {
              from: accounts[1],
            })
          ).toString()
        ).to.equal("5");

        await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

        await helpers.levelUpTo(character1ID, 30, { characters });

        await pvpArena.enterArena(character1ID, weapon1ID, 0, false, {
          from: accounts[1],
        });

        expect(
          (
            await pvpArena.rankingPointsByCharacter(character1ID, {
              from: accounts[1],
            })
          ).toString()
        ).to.equal("0");
      });

      it("should reset character's rank and place it in current season if it's off-season. Resets rankings by tier as well (leaderboard)", async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "101",
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

        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

        let duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        const previousLeaderBoard = await pvpArena.getTierTopCharacters(
          await pvpArena.getArenaTier(character1ID)
        );

        expect(previousLeaderBoard.length).to.equal(2);

        const isCharacter1RankingGreaterThanZero =
          (
            await pvpArena.rankingPointsByCharacter(character1ID, {
              from: accounts[1],
            })
          ).toString() > 0;

        expect(isCharacter1RankingGreaterThanZero).to.equal(true);

        await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

        await pvpArena.restartRankedSeason();
        
        await pvpArena.enterArena(character1ID, weapon1ID, 0, false, {
          from: accounts[1],
        });

        expect(
          (
            await pvpArena.rankingPointsByCharacter(character1ID, {
              from: accounts[1],
            })
          ).toString()
        ).to.equal("0");

        const currentSeason = (await pvpArena.currentRankedSeason()).toString();

        expect(
          (await pvpArena.seasonByCharacter(character1ID)).toString()
        ).to.equal(currentSeason);
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

      it("should add pre-existing wager for characters re-entering arena", async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "101",
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
        const weapon3ID = await helpers.createWeapon(
          accounts[3],
          "161",
          helpers.elements.earth,
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

        const previousWager = (await pvpArena.fighterByCharacter(character2ID)).wager;

        await characters.setTrait(character1ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character2ID, helpers.elements.fire, {
          from: accounts[0],
        });

        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

        let duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

        duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

        character3ID = await createCharacterInPvpTier(
          accounts[3],
          2,
          "222",
          weapon3ID
        );

        await characters.setTrait(character3ID, helpers.elements.earth, {
          from: accounts[0],
        });

        // Now we make character 2 win one so he gets a non-fractional excedent
        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character2ID, {
          from: accounts[2],
        });

        await pvpArena.prepareDuel(character2ID, { from: accounts[2], value: await pvpArena.duelOffsetCost() });

        duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        await pvpArena.withdrawFromArena(character3ID, { from: accounts[3] });

        // Now we defeat him again to kick him
        await pvpArena.enterArena(character1ID, weapon1ID, 0, false, {
          from: accounts[1],
        });

        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

        duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        const wager = await pvpArena.excessWagerByCharacter(character2ID);

        const isWagerPositive = wager > toBN(0);

        const isCharacterInArena = await pvpArena.isCharacterInArena(
          character2ID
        );

        expect(isCharacterInArena).to.equal(false);
        expect(isWagerPositive).to.equal(true);

        await pvpArena.enterArena(character2ID, weapon2ID, 0, false, {
          from: accounts[2],
        });

        const newWager = (await pvpArena.fighterByCharacter(character2ID)).wager;

        const isNewWagerValid =
          newWager.toString() === previousWager.add(wager).toString();

        expect(isNewWagerValid).to.equal(true);
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
          "Char busy"
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
          "Wpn busy"
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
          "Shld busy"
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
        await expectRevert.unspecified(
          pvpArena.enterArena(otherCharacterId, weaponId, 0, false, {
            from: accounts[1],
          })
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

  describe("#findOpponent", () => {
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

    describe("already in match", () => {
      let character0ID;

      beforeEach(async () => {
        character0ID = await createCharacterInPvpTier(accounts[1], 2, "000");
        character1ID = await createCharacterInPvpTier(accounts[2], 2, "111");
        character2ID = await createCharacterInPvpTier(accounts[2], 2, "222");
      });

      it("reverts", async () => {
        await pvpArena.findOpponent(character0ID, { from: accounts[1] });
        await expectRevert(
          pvpArena.findOpponent(character0ID, { from: accounts[1] }),
          "Already in match"
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
        await time.increase(await pvpArena.decisionSeconds());

        const { tx } = await pvpArena.findOpponent(character0ID, {
          from: accounts[1],
        });
        const opponentID = await pvpArena.getOpponent(character0ID, {
          from: accounts[1],
        });

        expect(opponentID.toString()).to.equal(character3ID.toString());
      });

      it("should not consider characters owned by the sender", async () => {
        const character2ID = await createCharacterInPvpTier(accounts[1], 8);
        await time.increase(await pvpArena.decisionSeconds());
        const characterID = await createCharacterInPvpTier(accounts[1], 8);

        await expectRevert(
          pvpArena.findOpponent(characterID, {
            from: accounts[1],
          }),
          "No enemy found"
        );
      });
    });

    describe("character not in the arena", () => {
      it("should revert", async () => {
        await expectRevert(
          pvpArena.findOpponent(character1ID, { from: accounts[1] }),
          "Not in arena"
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

        await time.increase(await pvpArena.decisionSeconds());

        const { tx } = await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        duelTx = tx;
      });

      it("should put the attacker in an active match", async () => {
        const isInMatch = (await pvpArena.matchByFinder(character1ID, {
          from: accounts[1],
        })).createdAt.toString() !== '0';

        expect(isInMatch).to.equal(true);
      });
    });

    describe("no opponent found", () => {
      it("should revert", async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 6);

        await expectRevert(
          pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          }),
          "No enemy found"
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

      expect(await pvpArena.isCharacterInArena(character1ID, {
        from: accounts[1],
      })).to.equal(true);

      expect(await pvpArena.isCharacterInArena(character2ID, {
        from: accounts[1],
      })).to.equal(true);

      await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

      expect(await pvpArena.isCharacterInArena(character1ID, {
        from: accounts[1],
      })).to.equal(false);

      expect(await pvpArena.isCharacterInArena(character2ID, {
        from: accounts[1],
      })).to.equal(true);

      await pvpArena.withdrawFromArena(character2ID, { from: accounts[1] });

      expect(await pvpArena.isCharacterInArena(character2ID, {
        from: accounts[1],
      })).to.equal(false);
    });

    it("should refund the wager", async () => {
      const character2ID = await createCharacterInPvpTier(
        accounts[1],
        1,
        "222"
      );
      const characterWager = (await pvpArena.fighterByCharacter(character2ID)).wager;
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

      const characterWager = (await pvpArena.fighterByCharacter(character1ID)).wager;
      const previousBalance = await skillToken.balanceOf(accounts[1]);

      const wagerMinusPenalty = toBN(characterWager - characterWager * (await pvpArena.withdrawFeePercent())/100);

      await time.increase(await pvpArena.decisionSeconds());
      await pvpArena.findOpponent(character1ID, {
        from: accounts[1],
      });

      await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });
      const newBalance = await skillToken.balanceOf(accounts[1]);

      expect(newBalance.toString()).to.equal(
        previousBalance.add(wagerMinusPenalty).toString()
      );
    });

    it("should withdraw the character's weapon", async () => {
      const weapon1ID = await helpers.createWeapon(accounts[1], "123", 0, { weapons });

      const character1ID = await createCharacterInPvpTier(
        accounts[1],
        4,
        "222",
        weapon1ID
      );

      expect(await pvpArena.isWeaponInArena(weapon1ID)).to.equal(true);

      await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

      expect(await pvpArena.isWeaponInArena(weapon1ID)).to.equal(false);
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

      expect(await pvpArena.isShieldInArena(shieldID)).to.equal(true);

      await pvpArena.withdrawFromArena(characterID, { from: accounts[1] });

      expect(await pvpArena.isShieldInArena(shieldID)).to.equal(false);
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
            "101",
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

          await time.increase(await pvpArena.decisionSeconds());
          await pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          });
          await pvpArena.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpArena.duelOffsetCost()
          });

          let duelQueue = await pvpArena.getDuelQueue();

          await pvpArena.performDuels(duelQueue, {
            from: accounts[0],
          });

          wager = (await pvpArena.fighterByCharacter(character1ID)).wager;
        });

        it("should pay the owner the character's earnings", async () => {
          const previousBalance = await skillToken.balanceOf(accounts[1]);
          await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

          const newWager = (await pvpArena.fighterByCharacter(character1ID)).wager;

          const balance = await skillToken.balanceOf(accounts[1]);

          expect(newWager.toString()).to.equal(toBN(0).toString());

          expect(balance.toString()).to.equal(
            previousBalance.add(wager).toString()
          );
        });
      });

      describe("with pending duel", () => {
        let character1ID;
        let character2ID;
        let wager;

        beforeEach(async () => {
          const weapon1ID = await helpers.createWeapon(
            accounts[1],
            "101",
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

          await time.increase(await pvpArena.decisionSeconds());
          await pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          });
          await pvpArena.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpArena.duelOffsetCost()
          });

          let duelQueue = await pvpArena.getDuelQueue();

          await pvpArena.performDuels(duelQueue, {
            from: accounts[0],
          });

          wager = (await pvpArena.fighterByCharacter(character1ID)).wager;

          await time.increase(await pvpArena.decisionSeconds());

          await pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          });
        });

        it("should return unclaimed earnings minus the penalty from the refunded amount", async () => {
          const previousBalance = await skillToken.balanceOf(accounts[1]);
          await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

          const newWager = (await pvpArena.fighterByCharacter(character1ID)).wager;

          const balance = await skillToken.balanceOf(accounts[1]);

          const entryWager = await pvpArena.getEntryWager(character1ID);

          expect(newWager.toString()).to.equal(toBN(0).toString());

          expect(balance.toString()).to.equal(
            previousBalance.add(wager.sub(entryWager.div(toBN(4)))).toString()
          );
        });

        it("should reset the character's duel", async () => {
          await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });

          const isInMatch = (await pvpArena.matchByFinder(character1ID)).createdAt.toString() !== '0';

          expect(isInMatch).to.equal(false);
        });
      });
    });

    describe("decision time expired", () => {
      let character1ID;
      let character2ID;
      let wager;

      beforeEach(async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "101",
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

        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });
        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

        let duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        wager = (await pvpArena.fighterByCharacter(character1ID)).wager;

        await time.increase(await pvpArena.decisionSeconds());

        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });
      });

      it("should subtract the penalty from the refunded amount", async () => {
        await time.increase(await pvpArena.decisionSeconds());

        const previousBalance = await skillToken.balanceOf(accounts[1]);

        await pvpArena.withdrawFromArena(character1ID, { from: accounts[1] });
        const newWager = (await pvpArena.fighterByCharacter(character1ID)).wager;

        const balance = await skillToken.balanceOf(accounts[1]);

        const entryWager = await pvpArena.getEntryWager(character1ID);

        expect(newWager.toString()).to.equal(toBN(0).toString());

        expect(balance.toString()).to.equal(
          previousBalance.add(wager.sub(entryWager.div(toBN(4)))).toString()
        );
      });
    });
  });

  describe("#prepareDuel", () => {
    let weapon1ID;
    let weapon2ID;
    let character1ID;
    let character2ID;

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
    });

    describe("happy path", () => {
      it("updates the duel queue", async () => {
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        const previousDuelQueue = await pvpArena.getDuelQueue();

        expect(previousDuelQueue.length).to.equal(0);

        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

        const newDuelQueue = await pvpArena.getDuelQueue();

        expect(newDuelQueue.length).to.equal(1);
      });

      it("transfers duelOffsetCost", async () => {
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        const duelOffsetCostInGwei = web3.utils.fromWei(await pvpArena.duelOffsetCost(), 'Gwei');

        const previousBalanceInGwei = web3.utils.fromWei(await web3.eth.getBalance(accounts[10]), 'Gwei');
        
        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });
        
        const nextBalanceInGwei = web3.utils.fromWei(await web3.eth.getBalance(accounts[10]), 'Gwei');
        
        expect(+nextBalanceInGwei).to.equal(+previousBalanceInGwei + +duelOffsetCostInGwei);
      });
    });

    describe("unhappy path", () => {
      it("reverts if decision time expired", async () => {
        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        await time.increase(await pvpArena.decisionSeconds());

        await expectRevert(
          pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() }),
          "Decision time expired"
        );
      });

      it("reverts if character is already in duel queue", async () => {
        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

        await expectRevert(
          pvpArena.prepareDuel(character1ID, { from: accounts[1] }),
          "In queue"
        );
      });
    });
  });

  describe("#performDuels", async () => {
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
            "101",
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

          await time.increase(await pvpArena.decisionSeconds());
          await pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          });

          character1Wager = (await pvpArena.fighterByCharacter(character1ID, {
            from: accounts[1],
          })).wager;
          character2Wager = (await pvpArena.fighterByCharacter(character2ID, {
            from: accounts[2],
          })).wager;

          await pvpArena.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpArena.duelOffsetCost()
          });

          let duelQueue = await pvpArena.getDuelQueue();

          const transaction = await pvpArena.performDuels(duelQueue, {
            from: accounts[0],
          });

          previousBalance = await skillToken.balanceOf(accounts[1]);
          duelEvent = await expectEvent.inTransaction(
            transaction.tx,
            pvpArena,
            "DuelFinished"
          );

          duelTx = transaction.tx;
          duelCost = await pvpArena.getDuelCost(character1ID, {
            from: accounts[1],
          });

          bounty = duelCost.mul(toBN(2));
          poolTax = bounty.mul(toBN(15)).div(toBN(100));
          winnerReward = bounty.sub(poolTax).sub(duelCost);
        });

        it("should add to the winner's earnings balance", async () => {
          const newWager = (await pvpArena.fighterByCharacter(character1ID)).wager;

          expect(newWager.toString()).to.equal(
            winnerReward.add(character1Wager).toString()
          );
        });

        it("should remove the duel cost from the loser's wager", async () => {
          const character2NewWager = (await pvpArena.fighterByCharacter(
            character2ID,
            {
              from: accounts[2],
            }
          )).wager;

          // should remove battleCost from the defender's wager
          expect(character2NewWager.toString()).to.equal(
            character2Wager.sub(duelCost).toString()
          );
        });

        it("Should remove defender from arena if his/her wager is lower than duel cost", async () => {
          // We make them duel until character2's wager is 0
          await time.increase(await pvpArena.decisionSeconds());
          await pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          });

          await pvpArena.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpArena.duelOffsetCost()
          });

          let duelQueue = await pvpArena.getDuelQueue();

          await pvpArena.performDuels(duelQueue, {
            from: accounts[0],
          });

          await time.increase(await pvpArena.decisionSeconds());
          await pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          });

          await pvpArena.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpArena.duelOffsetCost()
          });

          duelQueue = await pvpArena.getDuelQueue();

          await pvpArena.performDuels(duelQueue, {
            from: accounts[0],
          });

          await time.increase(await pvpArena.decisionSeconds());

          await expectRevert(
            pvpArena.findOpponent(character1ID, {
              from: accounts[1],
            }),
            "No enemy found"
          );
        });

        it("should save the ranking prize pool", async () => {
          const tier = await pvpArena.getArenaTier(character1ID, {
            from: accounts[1],
          });
          const rewardsInPool = await pvpArena.rankingsPoolByTier(tier, {
            from: accounts[1],
          });

          expect(rewardsInPool.toString()).to.equal(poolTax.div(toBN(2)).toString());
        });

        it("should emit the DuelFinished event", async () => {
          await expectEvent.inTransaction(duelTx, pvpArena, "DuelFinished");
        });

        it("should mark the attacker as no longer in an active duel", async () => {
          const isInMatch = (await pvpArena.matchByFinder(character1ID, {
            from: accounts[1],
          })).createdAt.toString() !== '0';

          expect(isInMatch).to.equal(false);
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
            "101",
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

          await time.increase(await pvpArena.decisionSeconds());
          await pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          });

          await pvpArena.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpArena.duelOffsetCost()
          });

          let duelQueue = await pvpArena.getDuelQueue();

          const { tx } = await pvpArena.performDuels(duelQueue, {
            from: accounts[0],
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
            "101",
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

          character1Wager = (await pvpArena.fighterByCharacter(character1ID, {
            from: accounts[1],
          })).wager;
          character2Wager = (await pvpArena.fighterByCharacter(character2ID, {
            from: accounts[2],
          })).wager;

          await time.increase(await pvpArena.decisionSeconds());
          await pvpArena.findOpponent(character1ID, {
            from: accounts[1],
          });

          await pvpArena.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpArena.duelOffsetCost()
          });

          let duelQueue = await pvpArena.getDuelQueue();

          const { tx } = await pvpArena.performDuels(duelQueue, {
            from: accounts[0],
          });

          duelTx = tx;
          bounty = duelCost.mul(toBN(2));
          poolTax = bounty.mul(toBN(15)).div(toBN(100));
          winnerReward = bounty.sub(poolTax).sub(duelCost);
        });

        it("should pay the defender their prize", async () => {
          const newWager = (await pvpArena.fighterByCharacter(character2ID)).wager;

          expect(newWager.toString()).to.equal(
            winnerReward.add(character2Wager).toString()
          );
        });

        it("should remove the duel cost from the attacker's wager", async () => {
          const character1NewWager = (await pvpArena.fighterByCharacter(
            character1ID,
            {
              from: accounts[1],
            }
          )).wager;

          expect(character1NewWager.toString()).to.equal(
            character1Wager.sub(toBN(duelCost)).toString()
          );
        });
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
          "Not in match"
        );
      });

      it("should transfer skill from the sender to the contract", async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 2);
        await createCharacterInPvpTier(accounts[2], 2);
        await createCharacterInPvpTier(accounts[3], 2);

        await time.increase(await pvpArena.decisionSeconds());

        await pvpArena.findOpponent(character1ID, {
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

      it("can reroll the same opponent", async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 2);
        const character2ID = await createCharacterInPvpTier(accounts[2], 2);

        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        expect((await pvpArena.matchByFinder(character1ID)).defenderID.toString()).to.equal(character2ID);

        await pvpArena.reRollOpponent(character1ID, {
          from: accounts[1],
        });

        expect((await pvpArena.matchByFinder(character1ID)).defenderID.toString()).to.equal(character2ID);
      });

      it("should assign a new opponent", async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 2);
        await createCharacterInPvpTier(accounts[2], 2);
        await createCharacterInPvpTier(accounts[3], 2);

        await pvpArena.findOpponent(character1ID, {
          from: accounts[1],
        });

        const opponentID = (await pvpArena.matchByFinder(character1ID)).defenderID.toString();

        let characterToMatchAfterReRoll;
        let accountToWithdrawFrom;

        if (opponentID === "1") {
          characterToMatchAfterReRoll = "2"
          accountToWithdrawFrom = accounts[2];
        } else {
          characterToMatchAfterReRoll = "1"
          accountToWithdrawFrom = accounts[3];
        }

        await time.increase(await pvpArena.decisionSeconds());

        await pvpArena.withdrawFromArena(opponentID, { from: accountToWithdrawFrom });

        await pvpArena.reRollOpponent(character1ID, {
          from: accounts[1],
        });

        expect((await pvpArena.matchByFinder(character1ID)).defenderID.toString()).to.equal(characterToMatchAfterReRoll);
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

        await time.increase(await pvpArena.decisionSeconds());

        await pvpArena.findOpponent(character0ID, {
          from: accounts[1],
        });
      });

      it("should return the opponent", async () => {
        const opponentID = await pvpArena.getOpponent(character0ID);

        expect(opponentID.toString()).to.equal(character1ID);
      });
    });
  });

  describe("rankingBehaviour", () => {
    let character1ID;
    let character2ID;
    let character3ID;
    let character4ID;
    let character5ID;
    let character6ID;
    let weapon1ID;
    let weapon2ID;
    let shieldID;
    let shield2ID;

    it("should see the shield", async () => {
      character1ID = await helpers.createCharacter(accounts[1], "152", {
        characters,
      });

      character2ID = await helpers.createCharacter(accounts[2], "152", {
        characters,
      });
      weapon1ID = await helpers.createWeapon(accounts[1], "123", 0, {
        weapons,
      });
      weapon2ID = await helpers.createWeapon(accounts[2], "123", 0, {
        weapons,
      });

      shieldID = await helpers.createShield(accounts[1], "123",  {
        shields,
      });
      shield2ID = await helpers.createShield(accounts[2], "123", {
        shields,
      });
      cost = await pvpArena.getEntryWager(character2ID, {
        from: accounts[1],
      });
      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[1],
      });
      await skillToken.approve(pvpArena.address, web3.utils.toWei(cost), {
        from: accounts[2],
      });
      await pvpArena.enterArena(character1ID, weapon1ID, shieldID, true, {
        from: accounts[1],
      });
      await pvpArena.enterArena(character2ID, weapon2ID, shield2ID, true, {
        from: accounts[2],
      });

      await time.increase(await pvpArena.decisionSeconds());
      await pvpArena.findOpponent(character1ID, {
        from: accounts[1],
      });

      // perform a duel making sure character4 is always going to win
      await pvpArena.prepareDuel(character1ID, {
        from: accounts[1],
        value: await pvpArena.duelOffsetCost()
      });

      let duelQueue = await pvpArena.getDuelQueue();

      await pvpArena.performDuels(duelQueue, {
        from: accounts[0],
      });
    });

    describe("entering the arena ", () => {
      it("should fill the rank with the first 4 players", async () => {
        character1ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        character2ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        //this char will be in a different tier
        character3ID = await createCharacterInPvpTier(accounts[2], 3, "222");
        character4ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character5ID = await createCharacterInPvpTier(accounts[2], 2, "222");
        character6ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        const characterTier = await pvpArena.getTierTopCharacters(await pvpArena.getArenaTier(character1ID), {
          from: accounts[1],
        });
        expect(characterTier[0].toString()).to.equal(character1ID.toString());
        expect(characterTier[2].toString()).to.equal(character4ID.toString());
      });
    });

    describe("Ranking reset", () => {
      it("should reset the ranking of a character after advancing tier", async () => {
        character1ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        character2ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        weapon2ID = await helpers.createWeapon(accounts[1], "123", 0, {
          weapons,
        });

        await pvpArena.setRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character2ID, 34, {
          from: accounts[0],
        });

        const previousRankingPoints = await pvpArena.rankingPointsByCharacter(
          character2ID
        );
        await helpers.levelUpTo(character2ID, 30, { characters });

        await pvpArena.withdrawFromArena(character2ID, {from: accounts[1] });
        await pvpArena.enterArena(character2ID, weapon2ID, 0, false, { from: accounts[1] });

        const postRankingPoints = await pvpArena.rankingPointsByCharacter(
          character2ID
        );
        expect(previousRankingPoints.toString()).to.equal("34");
        expect(postRankingPoints.toString()).to.equal("0");
      });
      it("should not reset the rakning if the player levels up but doesn't skip a tier", async () => {
        character1ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        character2ID = await createCharacterInPvpTier(accounts[1], 2, "222");
        weapon2ID = await helpers.createWeapon(accounts[1], "123", 0, {
          weapons,
        });

        await pvpArena.setRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpArena.setRankingPoints(character2ID, 34, {
          from: accounts[0],
        });
        const previousRankingPoints = await pvpArena.rankingPointsByCharacter(
          character2ID
        );
        await helpers.levelUpTo(character2ID, 8, { characters });

        await pvpArena.withdrawFromArena(character2ID, {from: accounts[1] });
        await pvpArena.enterArena(character2ID, weapon2ID, 0, false, { from: accounts[1] });

        const postRankingPoints = await pvpArena.rankingPointsByCharacter(
          character2ID
        );
        expect(previousRankingPoints.toString()).to.equal("34");
        expect(postRankingPoints.toString()).to.equal("34");
      });
    });

    describe("after the fight", () => {
      it("update the ranks of both the winner and the loser and add/subtract points respectively", async () => {
        const winningPoints = await pvpArena.winningPoints();
        const losingPoints = await pvpArena.losingPoints();
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "101",
          helpers.elements.water,
          {
            weapons,
          }
        );
        weapon2ID = await helpers.createWeapon(
          accounts[1],
          "199",
          helpers.elements.fire,
          {
            weapons,
          }
        );
        character1ID = await createCharacterInPvpTier(
          accounts[1],
          2,
          "199",
          weapon2ID
        );
        character2ID = await createCharacterInPvpTier(accounts[2], 2);
        character3ID = await createCharacterInPvpTier(accounts[2], 2, "199");
        character4ID = await createCharacterInPvpTier(
          accounts[2],
          2,
          "201",
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
          await pvpArena.rankingPointsByCharacter(character4ID);
        const loserPreviousRankPoints =
          await pvpArena.rankingPointsByCharacter(character1ID);

        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character4ID, {
          from: accounts[2],
        });

        // perform a duel making sure character4 is always going to win
        await pvpArena.prepareDuel(character4ID, { from: accounts[2], value: await pvpArena.duelOffsetCost() });

        let duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        const winnerPostRankPoints = await pvpArena.rankingPointsByCharacter(
          character4ID
        );
        const loserPostRankPoints = await pvpArena.rankingPointsByCharacter(
          character1ID
        );

        // get the post  duel ranking points
        const playerTier = await pvpArena.getTierTopCharacters(await pvpArena.getArenaTier(character1ID), {
          from: accounts[1],
        });
        // expect the last player to be the first and the former first player to not be in the ranks
        expect(playerTier[0].toString()).to.equal(character4ID.toString());
        expect(playerTier[2].toString()).to.equal(character3ID.toString());
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
          "101",
          helpers.elements.water,
          {
            weapons,
          }
        );
        weapon2ID = await helpers.createWeapon(
          accounts[1],
          "199",
          helpers.elements.fire,
          {
            weapons,
          }
        );
        character1ID = await createCharacterInPvpTier(
          accounts[1],
          2,
          "299",
          weapon2ID
        );
        character2ID = await createCharacterInPvpTier(accounts[2], 2);
        character3ID = await createCharacterInPvpTier(accounts[2], 2, "299");
        character4ID = await createCharacterInPvpTier(accounts[2], 2, "299");
        character5ID = await createCharacterInPvpTier(accounts[2], 2, "299");
        character6ID = await createCharacterInPvpTier(
          accounts[2],
          2,
          "201",
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
        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character6ID, {
          from: accounts[2],
        });

        // perform a duel making sure character6 is always going to win
        await pvpArena.prepareDuel(character6ID, { from: accounts[2], value: await pvpArena.duelOffsetCost() });

        let duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });
        const playerTier = await pvpArena.getTierTopCharacters(await pvpArena.getArenaTier(character6ID));
        // expect the last character to be the first one, climibing through the entire ladder
        expect(playerTier[0].toString()).to.equal(character6ID).toString();
      });

      it("should process the winner and the loser with only 2 players inside the tier", async () => {
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "101",
          helpers.elements.water,
          {
            weapons,
          }
        );
        weapon2ID = await helpers.createWeapon(
          accounts[1],
          "199",
          helpers.elements.fire,
          {
            weapons,
          }
        );
        character1ID = await createCharacterInPvpTier(
          accounts[1],
          2,
          "299",
          weapon2ID
        );
        character2ID = await createCharacterInPvpTier(
          accounts[2],
          2,
          "201",
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

        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character2ID, {
          from: accounts[2],
        });

        // perform a duel making sure character1 is always going to lose, meaning character 2 will be the top 1
        await pvpArena.prepareDuel(character2ID, { from: accounts[2], value: await pvpArena.duelOffsetCost() });

        let duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        const playerTier = await pvpArena.getTierTopCharacters(await pvpArena.getArenaTier(character1ID));

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
          "201",
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

        await time.increase(await pvpArena.decisionSeconds());
        await pvpArena.findOpponent(character5ID, {
          from: accounts[2],
        });
        // perform a duel making sure character1 is always going to lose
        await pvpArena.prepareDuel(character5ID, { from: accounts[2], value: await pvpArena.duelOffsetCost() });

        let duelQueue = await pvpArena.getDuelQueue();

        await pvpArena.performDuels(duelQueue, {
          from: accounts[0],
        });

        // get the post  duel ranking points
        const playerTier = await pvpArena.getTierTopCharacters(await pvpArena.getArenaTier(character1ID), {
          from: accounts[1],
        });

        const isCharacterInTier = playerTier.some((player) => {
          player.toString() === character5ID.toString();
        });
        //expect loser player to remain in the same spot
        expect(isCharacterInTier).to.equal(false);
        expect(playerTier[2].toString()).to.equal(character1ID.toString());
      });
    });
  });

  describe("#restartRankedSeason", () => {
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

      await time.increase(await pvpArena.decisionSeconds());

      // We execute a duel so theres a prize pool
      await pvpArena.findOpponent(character1ID, {
        from: accounts[1],
      });

      await pvpArena.prepareDuel(character1ID, { from: accounts[1], value: await pvpArena.duelOffsetCost() });

      let duelQueue = await pvpArena.getDuelQueue();

      await pvpArena.performDuels(duelQueue, {
        from: accounts[0],
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

      await pvpArena.restartRankedSeason({ from: accounts[0] });

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

      await pvpArena.restartRankedSeason({ from: accounts[0] });

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

    it("resets ranking prize pools and updates ranked season", async () => {
      const balanceOne = await skillToken.balanceOf(accounts[1]);
      const balanceTwo = await skillToken.balanceOf(accounts[2]);

      const firstSeasonStartedAt = +(
        await pvpArena.seasonStartedAt()
      ).toString();

      expect((await pvpArena.currentRankedSeason()).toString()).to.equal("1");

      await pvpArena.restartRankedSeason({ from: accounts[0] });

      const secondSeasonStartedAt = +(
        await pvpArena.seasonStartedAt()
      ).toString();

      expect(secondSeasonStartedAt > firstSeasonStartedAt).to.equal(true);
      expect((await pvpArena.currentRankedSeason()).toString()).to.equal("2");

      await pvpArena.withdrawRankedRewards({ from: accounts[1] });
      await pvpArena.withdrawRankedRewards({ from: accounts[2] });

      const newerBalanceOne = await skillToken.balanceOf(accounts[1]);
      const newerBalanceTwo = await skillToken.balanceOf(accounts[2]);

      await pvpArena.restartRankedSeason({ from: accounts[0] });

      const thirdSeasonStartedAt = +(
        await pvpArena.seasonStartedAt()
      ).toString();

      expect(thirdSeasonStartedAt > secondSeasonStartedAt).to.equal(true);
      expect((await pvpArena.currentRankedSeason()).toString()).to.equal("3");

      const newestBalanceOne = await skillToken.balanceOf(accounts[1]);
      const newestBalanceTwo = await skillToken.balanceOf(accounts[2]);

      const didBalanceOneGrow = balanceOne < newerBalanceOne;
      const didBalanceTwoGrow = balanceTwo < newerBalanceTwo;

      const didBalanceOneGrowAgain = newerBalanceOne < newestBalanceOne;
      const didBalanceTwoGrowAgain = newerBalanceTwo < newestBalanceTwo;

      expect(didBalanceOneGrow).to.equal(true);
      expect(didBalanceTwoGrow).to.equal(true);
      expect(didBalanceOneGrowAgain).to.equal(false);
      expect(didBalanceTwoGrowAgain).to.equal(false);
    });
  });

  describe("#InteractionsWithOtherContracts", () => {
    let character1ID;
    let character2ID;
    let weapon1ID;
    let weapon2ID;
    let shieldID;
    it("should not allow a player to join the arena if he is busy", async () => {
      // Due to the issues with  starting a raid from here, for now we are testing this against the same arena
      // commenting the necessary code for future uses
      // await raid1.doRaid(1000, 100, 1, { from: accounts[0] });
      // const character1ID = await helpers.createCharacter(accounts[0], "123", {
      //   characters,
      // });
      // await raid1.joinRaid(character1ID, weapon1ID, { from: accounts[0] });
      weapon1ID = await helpers.createWeapon(accounts[0], "123", 0, {
        weapons,
      });
      character1ID = await createCharacterInPvpTier(accounts[0], 1);
      await expectRevert(
        pvpArena.enterArena(character1ID, weapon1ID, 0, false, {
          from: accounts[0],
        }),
        "Char busy"
      );
    });

    it("should not allow a player to join a raid if he is already busy", async () => {
      weapon1ID = await helpers.createWeapon(accounts[0], "123", 0, {
        weapons,
      });
      character1ID = await createCharacterInPvpTier(accounts[0], 1);

      await expectRevert(
        raid1.joinRaid(character1ID, weapon1ID),
        "Cannot join raid right now!"
      );
    });
    it("should not allow a weapon to join a raid if it is already busy", async () => {
      weapon1ID = await helpers.createWeapon(accounts[0], "123", 0, {
        weapons,
      });
      character1ID = await createCharacterInPvpTier(
        accounts[0],
        1,
        "222",
        weapon1ID
      );
      character2ID = await helpers.createCharacter(accounts[0], "123", {
        characters,
      });

      await expectRevert(
        raid1.joinRaid(character2ID, weapon1ID),
        "Cannot join raid right now!"
      );
    });

    // it("should not allow a player to perform a regular fight if he is busy", async () => {
    //   weapon1ID = await helpers.createWeapon(accounts[0], "123", 0, {
    //     weapons,
    //   });
    //   character1ID = await createCharacterInPvpTier(accounts[0], 1);

    //   await expectRevert(
    //     characters.getFightDataAndDrainStamina(accounts[0], character1ID, 0, false, 1),
    //     "Character is busy"
    //   );
    // });
  });
});