const {
  expectRevert,
  expectEvent,
  time,
} = require("@openzeppelin/test-helpers");
const helpers = require("./helpers");

const { BN, toBN, fromWei } = web3.utils;

contract("PvpCore", (accounts) => {
  let pvpCore, pvpRankings, characters, weapons, shields, priceOracle, randoms, raid1;

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

    const cost = await pvpCore.getEntryWager(characterID, { from: account });

    await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
      from: account,
    });

    await pvpCore.enterArena(characterID, weaponIDToUse, 0, false, false, {
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
    pvpCore = contracts.pvpCore;
    pvpRankings = contracts.pvpRankings;
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

    await pvpCore.grantRole(await pvpCore.GAME_ADMIN(), accounts[0]);
    await pvpRankings.grantRole(await pvpRankings.GAME_ADMIN(), accounts[0]);
    await characters.grantRole(await characters.GAME_ADMIN(), accounts[0]);
    await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[1]);
    await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[2]);
    await weapons.grantRole(await weapons.GAME_ADMIN(), accounts[0]);
    await shields.grantRole(await shields.GAME_ADMIN(), accounts[0]);
    await raid1.grantRole(await raid1.GAME_ADMIN(), accounts[0]);
    
    await pvpCore.setArenaAccess(1, { from: accounts[0] });
    await pvpCore.setPvpBotAddress(accounts[10], { from: accounts[0] });
  });

  describe("#getDuelCost", () => {
    it("should return the correct cost", async () => {
      const charID = await createCharacterInPvpTier(accounts[1], 5, "888");
      const cost = await pvpCore.getDuelCost(charID, { from: accounts[1] });

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
      const character0arenaTier = await pvpCore.getArenaTier(character0ID, {
        from: accounts[1],
      });
      const character1arenaTier = await pvpCore.getArenaTier(character1ID, {
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
      shieldId = await helpers.createShield(accounts[1], 0, "123", { shields });
      characterID = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
    });

    describe("happy path", async () => {
      beforeEach(async () => {
        cost = await pvpCore.getEntryWager(characterID, { from: accounts[1] });
        await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        await pvpCore.enterArena(
          characterID,
          weaponId,
          0,
          false,
          false,
          {
            from: accounts[1],
          }
        );
      });

      it("should place character in current season if it had never entered PVP before", async () => {
        const currentSeason = (await pvpRankings.currentRankedSeason()).toString();

        character1ID = await createCharacterInPvpTier(accounts[1], 2);

        expect(
          (await pvpRankings.seasonByCharacter(character1ID)).toString()
        ).to.equal(currentSeason);
      });

      it("should reset character's rank if it changes tier", async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "100",
          helpers.elements.water,
          {
            weapons,
          }
        );
        const weapon2ID = await helpers.createWeapon(
          accounts[2],
          "199",
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

        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

        let duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        expect(
          (
            await pvpRankings.rankingPointsByCharacter(character1ID, {
              from: accounts[1],
            })
          ).toString()
        ).to.equal("5");

        await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });

        await helpers.levelUpTo(character1ID, 30, { characters });

        await pvpCore.enterArena(character1ID, weapon1ID, 0, false, false, {
          from: accounts[1],
        });

        expect(
          (
            await pvpRankings.rankingPointsByCharacter(character1ID, {
              from: accounts[1],
            })
          ).toString()
        ).to.equal("0");
      });

      it("should reset character's rank and place it in current season if it's off-season. Resets rankings by tier as well (leaderboard)", async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "100",
          helpers.elements.water,
          {
            weapons,
          }
        );
        const weapon2ID = await helpers.createWeapon(
          accounts[2],
          "199",
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

        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

        let duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        const previousLeaderBoard = await pvpRankings.getTierTopCharacters(
          await pvpCore.getArenaTier(character1ID)
        );

        expect(previousLeaderBoard.length).to.equal(2);

        const isCharacter1RankingGreaterThanZero =
          (
            await pvpRankings.rankingPointsByCharacter(character1ID, {
              from: accounts[1],
            })
          ).toString() > 0;

        expect(isCharacter1RankingGreaterThanZero).to.equal(true);

        await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });

        await pvpRankings.restartRankedSeason();
        
        await pvpCore.enterArena(character1ID, weapon1ID, 0, false, false, {
          from: accounts[1],
        });

        expect(
          (
            await pvpRankings.rankingPointsByCharacter(character1ID, {
              from: accounts[1],
            })
          ).toString()
        ).to.equal("0");

        const currentSeason = (await pvpRankings.currentRankedSeason()).toString();

        expect(
          (await pvpRankings.seasonByCharacter(character1ID)).toString()
        ).to.equal(currentSeason);
      });

      it("should add the character with its weapon and shield to the arena", async () => {
        const isCharacterInArena = await pvpCore.isCharacterInArena(
          characterID
        );
        const fighter = await pvpCore.fighterByCharacter(characterID);

        expect(isCharacterInArena).to.equal(true);
        expect(fighter.characterID.toString()).to.equal(
          toBN(characterID).toString()
        );
      });

      it("should add pre-existing wager for characters re-entering arena", async () => {
        const weapon1ID = await helpers.createWeapon(
          accounts[1],
          "100",
          helpers.elements.water,
          {
            weapons,
          }
        );
        const weapon2ID = await helpers.createWeapon(
          accounts[2],
          "130",
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

        const previousWager = (await pvpCore.fighterByCharacter(character2ID)).wager;

        await characters.setTrait(character1ID, helpers.elements.water, {
          from: accounts[0],
        });
        await characters.setTrait(character2ID, helpers.elements.fire, {
          from: accounts[0],
        });

        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

        let duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

        duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });

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
        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character2ID, {
          from: accounts[2],
        });

        await pvpCore.prepareDuel(character2ID, { from: accounts[2], value: await pvpCore.duelOffsetCost() });

        duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        await pvpCore.withdrawFromArena(character3ID, { from: accounts[3] });

        // Now we defeat him again to kick him
        await pvpCore.enterArena(character1ID, weapon1ID, 0, false, false, {
          from: accounts[1],
        });

        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

        duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        const wager = await pvpCore.excessWagerByCharacter(character2ID);

        const isWagerPositive = wager > toBN(0);

        const isCharacterInArena = await pvpCore.isCharacterInArena(
          character2ID
        );

        expect(isCharacterInArena).to.equal(false);
        expect(isWagerPositive).to.equal(true);

        await pvpCore.enterArena(character2ID, weapon2ID, 0, false, false, {
          from: accounts[2],
        });

        const newWager = (await pvpCore.fighterByCharacter(character2ID)).wager;

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

        const cost = await pvpCore.getEntryWager(characterID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        pvpCore.enterArena(characterID, weaponId, 0, false, false, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        const cost = await pvpCore.getEntryWager(characterID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });

        await expectRevert(
          pvpCore.enterArena(characterID, weapon2Id, 0, false, false, {
            from: accounts[1],
          }),
          "B"
        );
      });
    });

    describe("weapon already in arena", () => {
      beforeEach(async () => {
        character2ID = await helpers.createCharacter(accounts[1], "443", {
          characters,
        });

        cost = await pvpCore.getEntryWager(characterID, { from: accounts[1] });

        await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        await pvpCore.enterArena(characterID, weaponId, 0, false, false, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        cost = await pvpCore.getEntryWager(character2ID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });

        await expectRevert(
          pvpCore.enterArena(character2ID, weaponId, 0, false, false, {
            from: accounts[1],
          }),
          "B"
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
        shieldId = await helpers.createShield(accounts[1], 0, "446", { shields });

        cost = await pvpCore.getEntryWager(character2ID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
        await pvpCore.enterArena(characterID, weaponId, shieldId, true, false, {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        cost = await pvpCore.getEntryWager(character2ID, {
          from: accounts[1],
        });
        await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });

        await expectRevert(
          pvpCore.enterArena(character2ID, weapon2Id, shieldId, true, {
            from: accounts[1],
          }),
          "S"
        );
      });
    });

    describe("character is not sender's", () => {
      let otherCharacterId;

      beforeEach(async () => {
        otherCharacterId = await helpers.createCharacter(accounts[2], "123", {
          characters,
        });

        cost = await pvpCore.getEntryWager(characterID, {
          from: accounts[1],
        });

        await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
          from: accounts[1],
        });
      });

      it("should revert", async () => {
        await expectRevert.unspecified(
          pvpCore.enterArena(otherCharacterId, weaponId, 0, false, {
            from: accounts[1],
          })
        );
      });
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
        await pvpCore.findOpponent(character0ID, { from: accounts[1] });
        await expectRevert(
          pvpCore.findOpponent(character0ID, { from: accounts[1] }),
          "M"
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
        await time.increase(await pvpCore.decisionSeconds());

        const { tx } = await pvpCore.findOpponent(character0ID, {
          from: accounts[1],
        });
        const opponentID = await pvpCore.getOpponent(character0ID, {
          from: accounts[1],
        });

        expect(opponentID.toString()).to.equal(character3ID.toString());
      });

      it("should not consider characters owned by the sender", async () => {
        await createCharacterInPvpTier(accounts[1], 8);
        await time.increase(await pvpCore.decisionSeconds());
        const characterID = await createCharacterInPvpTier(accounts[1], 8);

        await expectRevert(
          pvpCore.findOpponent(characterID, {
            from: accounts[1],
          }),
          "E"
        );
      });
    });

    describe("character not in the arena", () => {
      it("should revert", async () => {
        await expectRevert.unspecified(
          pvpCore.findOpponent(character1ID, { from: accounts[1] })
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

        await time.increase(await pvpCore.decisionSeconds());

        const { tx } = await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        duelTx = tx;
      });

      it("should put the attacker in an active match", async () => {
        const isInMatch = (await pvpCore.matchByFinder(character1ID, {
          from: accounts[1],
        })).createdAt.toString() !== '0';

        expect(isInMatch).to.equal(true);
      });
    });

    describe("no opponent found", () => {
      it("should revert", async () => {
        const character1ID = await createCharacterInPvpTier(accounts[1], 6);

        await expectRevert(
          pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          }),
          "E"
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

      expect(await pvpCore.isCharacterInArena(character1ID, {
        from: accounts[1],
      })).to.equal(true);

      expect(await pvpCore.isCharacterInArena(character2ID, {
        from: accounts[1],
      })).to.equal(true);

      await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });

      expect(await pvpCore.isCharacterInArena(character1ID, {
        from: accounts[1],
      })).to.equal(false);

      expect(await pvpCore.isCharacterInArena(character2ID, {
        from: accounts[1],
      })).to.equal(true);

      await pvpCore.withdrawFromArena(character2ID, { from: accounts[1] });

      expect(await pvpCore.isCharacterInArena(character2ID, {
        from: accounts[1],
      })).to.equal(false);
    });

    it("should refund the wager", async () => {
      const character2ID = await createCharacterInPvpTier(
        accounts[1],
        1,
        "222"
      );
      const characterWager = (await pvpCore.fighterByCharacter(character2ID)).wager;
      const previousBalance = await skillToken.balanceOf(accounts[1]);
      await pvpCore.withdrawFromArena(character2ID, { from: accounts[1] });

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

      const characterWager = (await pvpCore.fighterByCharacter(character1ID)).wager;
      const previousBalance = await skillToken.balanceOf(accounts[1]);

      const wagerMinusPenalty = toBN(characterWager - characterWager * (await pvpCore.withdrawFeePercent())/100);

      await time.increase(await pvpCore.decisionSeconds());
      await pvpCore.findOpponent(character1ID, {
        from: accounts[1],
      });

      await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });
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

      expect(await pvpCore.isWeaponInArena(weapon1ID)).to.equal(true);

      await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });

      expect(await pvpCore.isWeaponInArena(weapon1ID)).to.equal(false);
    });

    it("should withdraw the character's shield", async () => {
      const characterID = await helpers.createCharacter(accounts[1], "123", {
        characters,
      });
      const shieldID = await helpers.createShield(accounts[1], 0, "123", {
        shields,
      });
      const weaponID = await helpers.createWeapon(accounts[1], "123", 0, {
        weapons,
      });

      const cost = await pvpCore.getEntryWager(characterID, {
        from: accounts[1],
      });

      await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
        from: accounts[1],
      });
      await pvpCore.enterArena(characterID, weaponID, shieldID, true, false, {
        from: accounts[1],
      });

      expect(await pvpCore.isShieldInArena(shieldID)).to.equal(true);

      await pvpCore.withdrawFromArena(characterID, { from: accounts[1] });

      expect(await pvpCore.isShieldInArena(shieldID)).to.equal(false);
    });

    describe("with unclaimed earnings", async () => {
      describe("happy path", () => {
        let character1ID;
        let character2ID;
        let wager;

        beforeEach(async () => {
          const weapon1ID = await helpers.createWeapon(
            accounts[1],
            "100",
            helpers.elements.water,
            {
              weapons,
            }
          );
          const weapon2ID = await helpers.createWeapon(
            accounts[2],
            "199",
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

          await time.increase(await pvpCore.decisionSeconds());
          await pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          });
          await pvpCore.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpCore.duelOffsetCost()
          });

          let duelQueue = await pvpCore.getDuelQueue();

          await pvpCore.performDuels(duelQueue, {
            from: accounts[0],
          });

          wager = (await pvpCore.fighterByCharacter(character1ID)).wager;
        });

        it("should pay the owner the character's earnings", async () => {
          const previousBalance = await skillToken.balanceOf(accounts[1]);
          await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });

          const newWager = (await pvpCore.fighterByCharacter(character1ID)).wager;

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
            "100",
            helpers.elements.water,
            {
              weapons,
            }
          );
          const weapon2ID = await helpers.createWeapon(
            accounts[2],
            "199",
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

          await time.increase(await pvpCore.decisionSeconds());
          await pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          });
          await pvpCore.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpCore.duelOffsetCost()
          });

          let duelQueue = await pvpCore.getDuelQueue();

          await pvpCore.performDuels(duelQueue, {
            from: accounts[0],
          });

          wager = (await pvpCore.fighterByCharacter(character1ID)).wager;

          await time.increase(await pvpCore.decisionSeconds());

          await pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          });
        });

        it("should return unclaimed earnings minus the penalty from the refunded amount", async () => {
          const previousBalance = await skillToken.balanceOf(accounts[1]);
          await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });

          const newWager = (await pvpCore.fighterByCharacter(character1ID)).wager;

          const balance = await skillToken.balanceOf(accounts[1]);

          const entryWager = await pvpCore.getEntryWager(character1ID);

          expect(newWager.toString()).to.equal(toBN(0).toString());

          expect(balance.toString()).to.equal(
            previousBalance.add(wager.sub(entryWager.div(toBN(4)))).toString()
          );
        });

        it("should reset the character's duel", async () => {
          await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });

          const isInMatch = (await pvpCore.matchByFinder(character1ID)).createdAt.toString() !== '0';

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
          "100",
          helpers.elements.water,
          {
            weapons,
          }
        );
        const weapon2ID = await helpers.createWeapon(
          accounts[2],
          "199",
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

        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });
        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

        let duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        wager = (await pvpCore.fighterByCharacter(character1ID)).wager;

        await time.increase(await pvpCore.decisionSeconds());

        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });
      });

      it("should subtract the penalty from the refunded amount", async () => {
        await time.increase(await pvpCore.decisionSeconds());

        const previousBalance = await skillToken.balanceOf(accounts[1]);

        await pvpCore.withdrawFromArena(character1ID, { from: accounts[1] });
        const newWager = (await pvpCore.fighterByCharacter(character1ID)).wager;

        const balance = await skillToken.balanceOf(accounts[1]);

        const entryWager = await pvpCore.getEntryWager(character1ID);

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
        "100",
        helpers.elements.water,
        {
          weapons,
        }
      );
      weapon2ID = await helpers.createWeapon(
        accounts[2],
        "199",
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
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        const previousDuelQueue = await pvpCore.getDuelQueue();

        expect(previousDuelQueue.length).to.equal(0);

        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

        const newDuelQueue = await pvpCore.getDuelQueue();

        expect(newDuelQueue.length).to.equal(1);
      });

      it("transfers duelOffsetCost", async () => {
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        const duelOffsetCostInGwei = web3.utils.fromWei(await pvpCore.duelOffsetCost(), 'Gwei');

        const previousBalanceInGwei = web3.utils.fromWei(await web3.eth.getBalance(accounts[10]), 'Gwei');
        
        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });
        
        const nextBalanceInGwei = web3.utils.fromWei(await web3.eth.getBalance(accounts[10]), 'Gwei');
        
        expect(+nextBalanceInGwei).to.equal(+previousBalanceInGwei + +duelOffsetCostInGwei);
      });
    });

    describe("unhappy path", () => {
      it("reverts if decision time expired", async () => {
        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        await time.increase(await pvpCore.decisionSeconds());

        await expectRevert(
          pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() }),
          "D"
        );
      });

      it("reverts if character is already in duel queue", async () => {
        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character1ID, {
          from: accounts[1],
        });

        await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

        await expectRevert(
          pvpCore.prepareDuel(character1ID, { from: accounts[1] }),
          "Q"
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
        let bounty;
        let poolTax;
        let winnerReward;

        beforeEach(async () => {
          // We create 2 identical characters with identical weapons, then
          // we make 1 effective against the other so that the result is always
          // the same
          const weapon1ID = await helpers.createWeapon(
            accounts[1],
            "100",
            helpers.elements.water,
            {
              weapons,
            }
          );
          const weapon2ID = await helpers.createWeapon(
            accounts[2],
            "199",
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

          await time.increase(await pvpCore.decisionSeconds());
          await pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          });

          character1Wager = (await pvpCore.fighterByCharacter(character1ID, {
            from: accounts[1],
          })).wager;
          character2Wager = (await pvpCore.fighterByCharacter(character2ID, {
            from: accounts[2],
          })).wager;

          await pvpCore.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpCore.duelOffsetCost()
          });

          let duelQueue = await pvpCore.getDuelQueue();

          const transaction = await pvpCore.performDuels(duelQueue, {
            from: accounts[0],
          });

          previousBalance = await skillToken.balanceOf(accounts[1]);
          await expectEvent.inTransaction(
            transaction.tx,
            pvpCore,
            "DuelFinished"
          );

          duelTx = transaction.tx;
          duelCost = await pvpCore.getDuelCost(character1ID, {
            from: accounts[1],
          });

          bounty = duelCost.mul(toBN(2));
          poolTax = bounty.mul(toBN(15)).div(toBN(100));
          winnerReward = bounty.sub(poolTax).sub(duelCost);
        });

        it("should add to the winner's earnings balance", async () => {
          const newWager = (await pvpCore.fighterByCharacter(character1ID)).wager;

          expect(newWager.toString()).to.equal(
            winnerReward.add(character1Wager).toString()
          );
        });

        it("should remove the duel cost from the loser's wager", async () => {
          const character2NewWager = (await pvpCore.fighterByCharacter(
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
          await time.increase(await pvpCore.decisionSeconds());
          await pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          });

          await pvpCore.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpCore.duelOffsetCost()
          });

          let duelQueue = await pvpCore.getDuelQueue();

          await pvpCore.performDuels(duelQueue, {
            from: accounts[0],
          });

          await time.increase(await pvpCore.decisionSeconds());
          await pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          });

          await pvpCore.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpCore.duelOffsetCost()
          });

          duelQueue = await pvpCore.getDuelQueue();

          await pvpCore.performDuels(duelQueue, {
            from: accounts[0],
          });

          await time.increase(await pvpCore.decisionSeconds());

          await expectRevert(
            pvpCore.findOpponent(character1ID, {
              from: accounts[1],
            }),
            "E"
          );
        });

        it("should save the ranking prize pool", async () => {
          const tier = await pvpCore.getArenaTier(character1ID, {
            from: accounts[1],
          });
          const rewardsInPool = await pvpRankings.rankingsPoolByTier(tier, {
            from: accounts[1],
          });

          expect(rewardsInPool.toString()).to.equal(poolTax.div(toBN(2)).toString());
        });

        it("should emit the DuelFinished event", async () => {
          await expectEvent.inTransaction(duelTx, pvpCore, "DuelFinished");
        });

        it("should mark the attacker as no longer in an active duel", async () => {
          const isInMatch = (await pvpCore.matchByFinder(character1ID, {
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
            "100",
            helpers.elements.water,
            {
              weapons,
            }
          );
          weapon2ID = await helpers.createWeapon(
            accounts[2],
            "199",
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

          await time.increase(await pvpCore.decisionSeconds());
          await pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          });

          await pvpCore.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpCore.duelOffsetCost()
          });

          let duelQueue = await pvpCore.getDuelQueue();

          const { tx } = await pvpCore.performDuels(duelQueue, {
            from: accounts[0],
          });

          duelTx = tx;
        });

        it("should apply bonus to the attacker", async () => {
          const duelEvent = await expectEvent.inTransaction(
            duelTx,
            pvpCore,
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
            "199",
            helpers.elements.fire,
            {
              weapons,
            }
          );
          weapon2ID = await helpers.createWeapon(
            accounts[2],
            "100",
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
          const duelCost = await pvpCore.getDuelCost(character1ID, {
            from: accounts[1],
          });

          await characters.setTrait(character1ID, helpers.elements.fire, {
            from: accounts[0],
          });
          await characters.setTrait(character2ID, helpers.elements.water, {
            from: accounts[0],
          });

          character1Wager = (await pvpCore.fighterByCharacter(character1ID, {
            from: accounts[1],
          })).wager;
          character2Wager = (await pvpCore.fighterByCharacter(character2ID, {
            from: accounts[2],
          })).wager;

          await time.increase(await pvpCore.decisionSeconds());
          await pvpCore.findOpponent(character1ID, {
            from: accounts[1],
          });

          await pvpCore.prepareDuel(character1ID, {
            from: accounts[1],
            value: await pvpCore.duelOffsetCost()
          });

          let duelQueue = await pvpCore.getDuelQueue();

          const { tx } = await pvpCore.performDuels(duelQueue, {
            from: accounts[0],
          });

          duelTx = tx;
          bounty = duelCost.mul(toBN(2));
          poolTax = bounty.mul(toBN(15)).div(toBN(100));
          winnerReward = bounty.sub(poolTax).sub(duelCost);
        });

        it("should pay the defender their prize", async () => {
          const newWager = (await pvpCore.fighterByCharacter(character2ID)).wager;

          expect(newWager.toString()).to.equal(
            winnerReward.add(character2Wager).toString()
          );
        });

        it("should remove the duel cost from the attacker's wager", async () => {
          const character1NewWager = (await pvpCore.fighterByCharacter(
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
  });

  describe("#reRollOpponent", () => {
    it("should fail if character is not dueling", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      await createCharacterInPvpTier(accounts[2], 2);

      await expectRevert(
        pvpCore.reRollOpponent(character1ID, {
          from: accounts[1],
        }),
        "M"
      );
    });

    it("should transfer skill from the sender to the contract", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      await createCharacterInPvpTier(accounts[2], 2);
      await createCharacterInPvpTier(accounts[3], 2);

      await time.increase(await pvpCore.decisionSeconds());

      await pvpCore.findOpponent(character1ID, {
        from: accounts[1],
      });

      const previousBalance = await skillToken.balanceOf(accounts[1]);

      await pvpCore.reRollOpponent(character1ID, {
        from: accounts[1],
      });

      const newBalance = await skillToken.balanceOf(accounts[1]);

      const duelCost = await pvpCore.getDuelCost(character1ID);

      const reRollPenalty = duelCost.div(toBN(4));

      expect(newBalance.toString()).to.equal(
        previousBalance.sub(reRollPenalty).toString()
      );
    });

    it("can reroll the same opponent", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      const character2ID = await createCharacterInPvpTier(accounts[2], 2);

      await pvpCore.findOpponent(character1ID, {
        from: accounts[1],
      });

      expect((await pvpCore.matchByFinder(character1ID)).defenderID.toString()).to.equal(character2ID);

      await pvpCore.reRollOpponent(character1ID, {
        from: accounts[1],
      });

      expect((await pvpCore.matchByFinder(character1ID)).defenderID.toString()).to.equal(character2ID);
    });

    it("should assign a new opponent", async () => {
      const character1ID = await createCharacterInPvpTier(accounts[1], 2);
      await createCharacterInPvpTier(accounts[2], 2);
      await createCharacterInPvpTier(accounts[3], 2);

      await pvpCore.findOpponent(character1ID, {
        from: accounts[1],
      });

      const opponentID = (await pvpCore.matchByFinder(character1ID)).defenderID.toString();

      let characterToMatchAfterReRoll;
      let accountToWithdrawFrom;

      if (opponentID === "1") {
        characterToMatchAfterReRoll = "2"
        accountToWithdrawFrom = accounts[2];
      } else {
        characterToMatchAfterReRoll = "1"
        accountToWithdrawFrom = accounts[3];
      }

      await time.increase(await pvpCore.decisionSeconds());

      await pvpCore.withdrawFromArena(opponentID, { from: accountToWithdrawFrom });

      await pvpCore.reRollOpponent(character1ID, {
        from: accounts[1],
      });

      expect((await pvpCore.matchByFinder(character1ID)).defenderID.toString()).to.equal(characterToMatchAfterReRoll);
    });
  });

  describe("#getOpponent", () => {
    describe("with pending duel", () => {
      let character0ID;
      let character1ID;

      beforeEach(async () => {
        character0ID = await createCharacterInPvpTier(accounts[1], 1);
        character1ID = await createCharacterInPvpTier(accounts[2], 1);

        await time.increase(await pvpCore.decisionSeconds());

        await pvpCore.findOpponent(character0ID, {
          from: accounts[1],
        });
      });

      it("should return the opponent", async () => {
        const opponentID = await pvpCore.getOpponent(character0ID);

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

      shieldID = await helpers.createShield(accounts[1], 0, "123",  {
        shields,
      });
      shield2ID = await helpers.createShield(accounts[2], 0, "123", {
        shields,
      });
      cost = await pvpCore.getEntryWager(character2ID, {
        from: accounts[1],
      });
      await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
        from: accounts[1],
      });
      await skillToken.approve(pvpCore.address, web3.utils.toWei(cost), {
        from: accounts[2],
      });
      await pvpCore.enterArena(character1ID, weapon1ID, shieldID, true, false, {
        from: accounts[1],
      });
      await pvpCore.enterArena(character2ID, weapon2ID, shield2ID, true, false, {
        from: accounts[2],
      });

      await time.increase(await pvpCore.decisionSeconds());
      await pvpCore.findOpponent(character1ID, {
        from: accounts[1],
      });

      // perform a duel making sure character4 is always going to win
      await pvpCore.prepareDuel(character1ID, {
        from: accounts[1],
        value: await pvpCore.duelOffsetCost()
      });

      let duelQueue = await pvpCore.getDuelQueue();

      await pvpCore.performDuels(duelQueue, {
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
        const characterTier = await pvpRankings.getTierTopCharacters(await pvpCore.getArenaTier(character1ID), {
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

        await pvpRankings.changeRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character2ID, 34, {
          from: accounts[0],
        });

        const previousRankingPoints = await pvpRankings.rankingPointsByCharacter(
          character2ID
        );
        await helpers.levelUpTo(character2ID, 30, { characters });

        await pvpCore.withdrawFromArena(character2ID, {from: accounts[1] });
        await pvpCore.enterArena(character2ID, weapon2ID, 0, false, false, { from: accounts[1] });

        const postRankingPoints = await pvpRankings.rankingPointsByCharacter(
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

        await pvpRankings.changeRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character2ID, 34, {
          from: accounts[0],
        });
        const previousRankingPoints = await pvpRankings.rankingPointsByCharacter(
          character2ID
        );
        await helpers.levelUpTo(character2ID, 8, { characters });

        await pvpCore.withdrawFromArena(character2ID, {from: accounts[1] });
        await pvpCore.enterArena(character2ID, weapon2ID, 0, false, false, { from: accounts[1] });

        const postRankingPoints = await pvpRankings.rankingPointsByCharacter(
          character2ID
        );
        expect(previousRankingPoints.toString()).to.equal("34");
        expect(postRankingPoints.toString()).to.equal("34");
      });
    });

    describe("after the fight", () => {
      it("update the ranks of both the winner and the loser and add/subtract points respectively", async () => {
        const winningPoints = await pvpRankings.winningPoints();
        const losingPoints = await pvpRankings.losingPoints();
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "100",
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
        await pvpRankings.changeRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character2ID, 34, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character3ID, 33, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character4ID, 32, {
          from: accounts[0],
        });

        const winnerPreviousRankPoints =
          await pvpRankings.rankingPointsByCharacter(character4ID);
        const loserPreviousRankPoints =
          await pvpRankings.rankingPointsByCharacter(character1ID);

        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character4ID, {
          from: accounts[2],
        });

        // perform a duel making sure character4 is always going to win
        await pvpCore.prepareDuel(character4ID, { from: accounts[2], value: await pvpCore.duelOffsetCost() });

        let duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        const winnerPostRankPoints = await pvpRankings.rankingPointsByCharacter(
          character4ID
        );
        const loserPostRankPoints = await pvpRankings.rankingPointsByCharacter(
          character1ID
        );

        // get the post  duel ranking points
        const playerTier = await pvpRankings.getTierTopCharacters(await pvpCore.getArenaTier(character1ID), {
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
          "100",
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

        await pvpRankings.changeRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character2ID, 34, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character3ID, 33, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character4ID, 32, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character5ID, 31, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character6ID, 30, {
          from: accounts[0],
        });
        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character6ID, {
          from: accounts[2],
        });

        // perform a duel making sure character6 is always going to win
        await pvpCore.prepareDuel(character6ID, { from: accounts[2], value: await pvpCore.duelOffsetCost() });

        let duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });
        const playerTier = await pvpRankings.getTierTopCharacters(await pvpCore.getArenaTier(character6ID));
        // expect the last character to be the first one, climibing through the entire ladder
        expect(playerTier[0].toString()).to.equal(character6ID).toString();
      });

      it("should process the winner and the loser with only 2 players inside the tier", async () => {
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "100",
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
        await pvpRankings.changeRankingPoints(character1ID, 15, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character2ID, 13, {
          from: accounts[0],
        });

        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character2ID, {
          from: accounts[2],
        });

        // perform a duel making sure character1 is always going to lose, meaning character 2 will be the top 1
        await pvpCore.prepareDuel(character2ID, { from: accounts[2], value: await pvpCore.duelOffsetCost() });

        let duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        const playerTier = await pvpRankings.getTierTopCharacters(await pvpCore.getArenaTier(character1ID));

        expect(playerTier[0].toString()).to.equal(character2ID).toString();
        expect(playerTier[1].toString()).to.equal(character1ID).toString();
        expect(playerTier[2]).to.equal(undefined);
      });
    });

    describe("loser path", () => {
      it("should not update the ranks if the loser is not within the top 4", async () => {
        weapon1ID = await helpers.createWeapon(
          accounts[2],
          "100",
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
        await pvpRankings.changeRankingPoints(character1ID, 35, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character2ID, 34, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character3ID, 33, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character4ID, 32, {
          from: accounts[0],
        });
        await pvpRankings.changeRankingPoints(character5ID, 10, {
          from: accounts[0],
        });

        await time.increase(await pvpCore.decisionSeconds());
        await pvpCore.findOpponent(character5ID, {
          from: accounts[2],
        });
        // perform a duel making sure character1 is always going to lose
        await pvpCore.prepareDuel(character5ID, { from: accounts[2], value: await pvpCore.duelOffsetCost() });

        let duelQueue = await pvpCore.getDuelQueue();

        await pvpCore.performDuels(duelQueue, {
          from: accounts[0],
        });

        // get the post  duel ranking points
        const playerTier = await pvpRankings.getTierTopCharacters(await pvpCore.getArenaTier(character1ID), {
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

  describe("#increaseRankingsPool", async () => {
    it('increases the ranking pool of a certain tier', async () => {
      const previousPool = (await pvpRankings.rankingsPoolByTier(1)).toString();
      expect(previousPool).to.equal('0');

      await pvpRankings.increaseRankingsPool(1, 1000);

      const newPool = (await pvpRankings.rankingsPoolByTier(1)).toString();
      expect(newPool).to.equal('1000');
    })

    it("doesn't increase other tier's pools", async () => {
      const previousPool = (await pvpRankings.rankingsPoolByTier(1)).toString();
      expect(previousPool).to.equal('0');

      await pvpRankings.increaseRankingsPool(2, 1000);

      const newPool = (await pvpRankings.rankingsPoolByTier(1)).toString();
      expect(newPool).to.equal('0');
    })
  });

  describe("#restartRankedSeason", () => {
    // These tests assume prizes will be distributed amongst at least 2 players and at most 4 players.
    beforeEach(async () => {
      character1ID = await createCharacterInPvpTier(accounts[1], 1);
      character2ID = await createCharacterInPvpTier(accounts[2], 1);

      await pvpRankings.changeRankingPoints(character1ID, 100, {
        from: accounts[0],
      });
      await pvpRankings.changeRankingPoints(character2ID, 80, {
        from: accounts[0],
      });

      await time.increase(await pvpCore.decisionSeconds());

      // We execute a duel so theres a prize pool
      await pvpCore.findOpponent(character1ID, {
        from: accounts[1],
      });

      await pvpCore.prepareDuel(character1ID, { from: accounts[1], value: await pvpCore.duelOffsetCost() });

      let duelQueue = await pvpCore.getDuelQueue();

      await pvpCore.performDuels(duelQueue, {
        from: accounts[0],
      });
    });

    it("distributes rewards correctly to top characters' owners", async () => {
      const prizePercentages = [
        await pvpRankings.prizePercentages(0), 
        await pvpRankings.prizePercentages(1), 
        await pvpRankings.prizePercentages(2)
      ];

      const character3ID = await createCharacterInPvpTier(accounts[3], 1);
      const character4ID = await createCharacterInPvpTier(accounts[4], 1);

      await pvpRankings.changeRankingPoints(character3ID, 60, {
        from: accounts[0],
      });
      await pvpRankings.changeRankingPoints(character4ID, 40, {
        from: accounts[0],
      });

      const balanceOne = await skillToken.balanceOf(accounts[1]);
      const balanceTwo = await skillToken.balanceOf(accounts[2]);
      const balanceThree = await skillToken.balanceOf(accounts[3]);
      const balanceFour = await skillToken.balanceOf(accounts[4]);

      await pvpRankings.restartRankedSeason({ from: accounts[0] });
      await pvpRankings.withdrawRankedRewards({ from: accounts[1] });
      await pvpRankings.withdrawRankedRewards({ from: accounts[2] });
      await pvpRankings.withdrawRankedRewards({ from: accounts[3] });
      await pvpRankings.withdrawRankedRewards({ from: accounts[4] });

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
      const prizePercentages = [
        await pvpRankings.prizePercentages(0), 
        await pvpRankings.prizePercentages(1), 
        await pvpRankings.prizePercentages(2)
      ];

      const balanceOne = await skillToken.balanceOf(accounts[1]);
      const balanceTwo = await skillToken.balanceOf(accounts[2]);

      await pvpRankings.restartRankedSeason({ from: accounts[0] });

      await pvpRankings.withdrawRankedRewards({ from: accounts[1] });
      await pvpRankings.withdrawRankedRewards({ from: accounts[2] });

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
        await pvpRankings.seasonStartedAt()
      ).toString();

      expect((await pvpRankings.currentRankedSeason()).toString()).to.equal("1");

      await pvpRankings.restartRankedSeason({ from: accounts[0] });

      const secondSeasonStartedAt = +(
        await pvpRankings.seasonStartedAt()
      ).toString();

      expect(secondSeasonStartedAt > firstSeasonStartedAt).to.equal(true);
      expect((await pvpRankings.currentRankedSeason()).toString()).to.equal("2");

      await pvpRankings.withdrawRankedRewards({ from: accounts[1] });
      await pvpRankings.withdrawRankedRewards({ from: accounts[2] });

      const newerBalanceOne = await skillToken.balanceOf(accounts[1]);
      const newerBalanceTwo = await skillToken.balanceOf(accounts[2]);

      await pvpRankings.restartRankedSeason({ from: accounts[0] });

      const thirdSeasonStartedAt = +(
        await pvpRankings.seasonStartedAt()
      ).toString();

      expect(thirdSeasonStartedAt > secondSeasonStartedAt).to.equal(true);
      expect((await pvpRankings.currentRankedSeason()).toString()).to.equal("3");

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
});