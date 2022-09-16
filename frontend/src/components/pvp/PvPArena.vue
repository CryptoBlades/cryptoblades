<template>
  <div>
    <div v-if="loading">
        <img class="loadingSpinner" src="../../assets/loadingSpinner.svg" />
    </div>
    <div v-else-if="!loading && isCharacterInOldArena">
      <p>
        {{$t('pvp.leaveOldArena')}}
      </p>
      <div class="buttonWrapper">
        <pvp-button
          @click="leaveOldArena"
          :disabled="loading"
          :buttonText="$t('pvp.leaveArena')"
          secondary
        />
      </div>
    </div>
    <div v-else>
      <pvp-arena-preparation
        v-if="!isCharacterInArena"
        :tierRewardsPool="tierRewardsPool"
        :untieredRewardsPool="untieredRewardsPool"
        :tierTopRankers="tierTopRankers"
        :untieredTopRankers="untieredTopRankers"
        :characterInformation="characterInformation"
        :entryWager="entryWager"
        :untieredEntryWager="untieredEntryWager"
        :withdrawCost="withdrawCost"
        :availableWeaponIds="availableWeaponIds"
        :availableShieldIds="availableShieldIds"
        :ownedWeaponsWithInformation="ownedWeaponsWithInformation"
        :ownedShieldsWithInformation="ownedShieldsWithInformation"
        :currentRankedSeason="currentRankedSeason"
        :secondsBeforeNextSeason="secondsBeforeNextSeason"
        @enteredArena="handleEnteredArena"
      />
      <pvp-arena-summary
        v-else-if="isCharacterInArena && !isMatchMaking"
        :tierRewardsPool="tierRewardsPool"
        :untieredRewardsPool="untieredRewardsPool"
        :tierTopRankers="tierTopRankers"
        :untieredTopRankers="untieredTopRankers"
        :characterInformation="characterInformation"
        :activeWeaponWithInformation="activeWeaponWithInformation"
        :activeShieldWithInformation="activeShieldWithInformation"
        :duelHistory="duelHistory"
        :currentRankedSeason="currentRankedSeason"
        :secondsBeforeNextSeason="secondsBeforeNextSeason"
        :opponentInformation="opponentInformation"
        :entryWager="entryWager"
        :withdrawCost="withdrawCost"
        @enterMatchMaking="handleEnterMatchMaking"
        @leaveArena="leaveArena"
      />
      <!-- Should use router -->
      <pvp-arena-matchmaking
        v-else-if="isCharacterInArena && isMatchMaking"
        :characterInformation="characterInformation"
        :activeWeaponWithInformation="activeWeaponWithInformation"
        :activeShieldWithInformation="activeShieldWithInformation"
        :opponentInformation="opponentInformation"
        :opponentActiveWeaponWithInformation="opponentActiveWeaponWithInformation"
        :opponentActiveShieldWithInformation="opponentActiveShieldWithInformation"
        :withdrawCost="withdrawCost"
        @updateOpponentInformation="updateOpponentInformation"
        @clearOpponentInformation="clearOpponentInformation"
        @kickCharacterFromArena="kickCharacterFromArena"
        @updateRank="updateRank"
        @leaveArena="leaveArena"
      />
    </div>
    <pvp-kicked-modal
      v-if="recentlyKicked.characterId"
      :kickedBy="recentlyKicked.kickedBy"
      @close-modal="handleCloseModal"
    />
  </div>
</template>

<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import PvPArenaPreparation from '../smart/PvPArenaPreparation.vue';
import PvPArenaSummary from '../smart/PvPArenaSummary.vue';
import PvPArenaMatchMaking from '../smart/PvPArenaMatchMaking.vue';
import PvPKickedModal from '../smart/PvPKickedModal.vue';
import PvPButton from '../smart/PvPButton.vue';
import { weaponFromContract as formatWeapon } from '../../contract-models';
import { shieldFromContract as formatShield } from '../../contract-models';
import { pvpFighterFromContract as formatFighter } from '../../contract-models';
import { characterFromContract as formatCharacter } from '../../contract-models';
import { duelResultFromContract as formatDuelResult } from '../../contract-models';
import { characterKickedEventFromContract as formatCharacterKickedEvent } from '../../contract-models';

export default {
  components: {
    'pvp-arena-preparation': PvPArenaPreparation,
    'pvp-arena-summary': PvPArenaSummary,
    'pvp-arena-matchmaking': PvPArenaMatchMaking,
    'pvp-kicked-modal': PvPKickedModal,
    'pvp-button': PvPButton,
  },

  data() {
    return {
      loading: true,
      isCharacterInArena: false,
      isCharacterInOldArena: false,
      entryWager: null,
      untieredEntryWager: null,
      isMatchMaking: false,
      tierRewardsPool: null,
      untieredRewardsPool: null,
      tierTopRankers: [],
      untieredTopRankers: [],
      currentRankedSeason: null,
      seasonStartedAt: null,
      seasonDuration: null,
      secondsBeforeNextSeason: null,
      restartEventSubscription: null,
      characterInformation: {
        tier: null,
        name: '',
        level: null,
        power: null,
        fullPower: null,
        untieredFullPower: null,
        rank: null,
        element: null,
      },
      availableWeaponIds: [],
      availableShieldIds: [],
      ownedWeaponsWithInformation: [],
      ownedShieldsWithInformation: [],
      activeWeaponWithInformation: {
        weaponId: null,
        information: {}
      },
      activeShieldWithInformation: {
        shieldId: null,
        information: {}
      },
      opponentInformation: {
        id: null,
        element: '',
        name: '',
        level: null,
        rank: null,
        power: null,
        fullPower: null,
        untieredFullPower: null
      },
      opponentActiveWeaponWithInformation: {
        weaponId: null,
        information: {}
      },
      opponentActiveShieldWithInformation: {
        shieldId: null,
        information: {}
      },
      duelHistory: [],
      recentlyKicked: {
        characterId: null,
        kickedBy: null
      },
      withdrawCost: null
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds', 'web3']),
    ...mapGetters(['getCharacterName'])
  },

  methods: {
    ...mapActions([
      'getWeapon',
      'getShield',
      'getCharacter',
      'getFighterByCharacter',
      'getCurrentRankedSeason',
      'getSeasonStartedAt',
      'getSeasonDuration',
      'getCharacterLevel',
      'getCharacterFullPower',
      'getRankingPointsByCharacter',
      'getRankingsPoolByTier',
      'getTierTopCharacters',
      'getArenaTier',
      'getEntryWagerByTier',
      'getIsWeaponInArena',
      'getIsShieldInArena',
      'getIsCharacterInArena',
      'getWithdrawFeePercent',
      'getMatchByFinder',
      'getIsCharacterInOldArena',
      'getPvpCoreContract',
      'getPvpRankingsContract',
      'getRename',
      'withdrawFromOldArena'
    ]),
    ...mapActions('combat', ['getCharacterPower']),

    async getWeaponInformation(weaponId) {
      return formatWeapon(`${weaponId}`, await this.getWeapon(weaponId));
    },

    async getShieldInformation(shieldId) {
      return formatShield(`${shieldId}`, await this.getShield(shieldId));
    },

    async handleEnteredArena() {
      this.loading = true;
      this.isCharacterInArena = true;

      const fighter = formatFighter(await this.getFighterByCharacter(this.currentCharacterId));

      this.characterInformation.fullPower = await this.getCharacterFullPower({characterId: this.currentCharacterId, tier: this.characterInformation.tier});
      this.characterInformation.untieredFullPower = await this.getCharacterFullPower({characterId: this.currentCharacterId, tier: 20});

      this.activeWeaponWithInformation = {
        weaponId: fighter.weaponID,
        information: await this.getWeaponInformation(fighter.weaponID)
      };

      if (fighter.useShield) {
        this.activeShieldWithInformation = {
          shieldId: fighter.shieldID,
          information: await this.getShieldInformation(fighter.shieldID)
        };
      }

      this.loading = false;
    },

    handleEnterMatchMaking() {
      this.isMatchMaking = true;
      this.$emit('enterMatchMaking');
    },

    leaveArena() {
      this.isCharacterInArena = false;
      this.isMatchMaking = false;
      this.$emit('leaveMatchMaking');
    },

    async updateSecondsBeforeSeason() {
      this.currentRankedSeason = await this.getCurrentRankedSeason();
      this.seasonStartedAt = await this.getSeasonStartedAt();
      this.seasonDuration = await this.getSeasonDuration();
      this.secondsBeforeNextSeason = (+this.seasonStartedAt + +this.seasonDuration) - (Math.floor(Date.now() / 1000));
    },

    async updateOpponentInformation(defenderId) {
      this.opponentInformation.id = defenderId;

      const rename = await this.getRename(defenderId);

      this.opponentInformation.name = rename ? rename : this.getCharacterName(defenderId);

      this.opponentInformation.level = Number(await this.getCharacterLevel(defenderId)) + 1;

      this.opponentInformation.rank = await this.getRankingPointsByCharacter(defenderId);

      this.opponentInformation.element = formatCharacter(defenderId, await this.getCharacter(defenderId)).traitName;

      this.opponentInformation.power = await this.getCharacterPower(defenderId);

      this.opponentInformation.fullPower = await this.getCharacterFullPower({characterId: defenderId, tier: this.characterInformation.tier});

      this.opponentInformation.untieredFullPower = await this.getCharacterFullPower({characterId: defenderId, tier: 20});

      const fighter = formatFighter(await this.getFighterByCharacter(defenderId));

      this.opponentActiveWeaponWithInformation = {
        weaponId: fighter.weaponID,
        information: await this.getWeaponInformation(fighter.weaponID)
      };

      if (fighter.useShield) {
        this.opponentActiveShieldWithInformation = {
          shieldId: fighter.shieldID,
          information: await this.getShieldInformation(fighter.shieldID)
        };
      }
    },

    clearOpponentInformation() {
      this.opponentInformation = {
        id: null,
        element: '',
        name: '',
        level: null,
        rank: null,
        power: null,
        fullPower: null,
        untieredFullPower: null,
      };

      this.opponentActiveWeaponWithInformation = {
        weaponId: null,
        information: {}
      };

      this.opponentActiveShieldWithInformation = {
        shieldId: null,
        information: {}
      };
    },

    async kickCharacterFromArena() {
      this.isCharacterInArena = false;

      await this.processCharacterKick();
    },

    async updateRank() {
      this.characterInformation.rank = await this.getRankingPointsByCharacter(this.currentCharacterId);
    },

    handleCloseModal() {
      this.recentlyKicked.characterId = null;
      this.recentlyKicked.kickedBy = null;
    },

    async getKickedEvents(pvpContract, blockToScanFrom) {
      let fromBlock;

      if (!blockToScanFrom) {
        fromBlock = Math.max(await this.web3.eth.getBlockNumber() - 1800, 0);
      } else {
        fromBlock = Math.max(blockToScanFrom, await this.web3.eth.getBlockNumber() - 1800);
      }

      const kickedEvents = await pvpContract.getPastEvents('CharacterKicked', {
        filter: { characterID: this.currentCharacterId },
        toBlock: 'latest',
        fromBlock,
      });

      return kickedEvents;
    },

    async processCharacterKick() {
      let blockToScanFrom;
      const lastKickedBlock = localStorage.getItem(`${this.currentCharacterId}-lastKickedBlock`);

      if (lastKickedBlock) {
        blockToScanFrom = lastKickedBlock;
      }

      const kickedEvents = await this.getKickedEvents(await this.getPvpCoreContract(), blockToScanFrom);

      if (kickedEvents.length && !this.isCharacterInArena) {
        const formattedResult = formatCharacterKickedEvent(kickedEvents[kickedEvents.length - 1].returnValues);
        const lastKickedEventBlockNumber = kickedEvents[kickedEvents.length - 1].blockNumber;

        const key = `${this.currentCharacterId}-lastKickedTime`;

        if (+localStorage.getItem(key) < +formattedResult.timestamp) {
          localStorage.setItem(key, +formattedResult.timestamp);
          localStorage.setItem(`${this.currentCharacterId}-lastKickedBlock`, lastKickedEventBlockNumber);

          this.recentlyKicked.characterId = formattedResult.characterId;
          this.recentlyKicked.kickedBy = formattedResult.kickedBy;
          const rename = await this.getRename(this.recentlyKicked.kickedBy);
          this.recentlyKicked.kickedBy = rename ? rename : await this.getCharacterName(formattedResult.kickedBy);
        }
      }
    },

    async listenForSeasonRestart(pvpContract, initialBlock) {
      let blockToScan = initialBlock;
      let scanning = false;

      const subscription = this.web3.eth.subscribe('newBlockHeaders', async (_, result) => {
        try {
          if (scanning) {
            return;
          }
          scanning = true;

          const seasonRestartedEvents = await pvpContract.getPastEvents('SeasonRestarted', {
            fromBlock: blockToScan,
            toBlock: 'latest',
          });

          blockToScan = result.number + 1;

          if (seasonRestartedEvents.length) {
            this.$dialog.notify.success('A new PvP season has begun!');
            await this.updateSecondsBeforeSeason();
          }

          this.tierRewardsPool = await this.getRankingsPoolByTier(this.characterInformation.tier);

          this.untieredRewardsPool = await this.getRankingsPoolByTier(20);

          const tierTopRankersIds = await this.getTierTopCharacters(this.characterInformation.tier);

          const untieredTopRankersIds = await this.getTierTopCharacters(20);

          this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
            const rename = await this.getRename(rankerId);
            return {
              rankerId,
              name: rename ? rename : this.getCharacterName(rankerId),
              rank: await this.getRankingPointsByCharacter(rankerId)
            };
          }));

          this.untieredTopRankers = await Promise.all(untieredTopRankersIds.map(async (rankerId) => {
            const rename = await this.getRename(rankerId);
            return {
              rankerId,
              name: rename ? rename : this.getCharacterName(rankerId),
              rank: await this.getRankingPointsByCharacter(rankerId)
            };
          }));
        } finally {
          scanning = false;
        }
      });

      this.restartEventSubscription = subscription;
    },

    async leaveOldArena() {
      this.loading = true;

      try {
        await this.withdrawFromOldArena(this.currentCharacterId);

        this.isCharacterInOldArena = false;
      } catch (err) {
        console.log('leave old arena error: ', err.message);
      } finally {
        this.loading = false;
      }
    },
  },

  async created() {
    const currentBlock = await this.web3.eth.getBlockNumber();

    await this.updateSecondsBeforeSeason();

    await this.listenForSeasonRestart(await this.getPvpRankingsContract(), currentBlock);

    // Note: currentCharacterId can be 0
    if (this.currentCharacterId !== null) {
      const rename = await this.getRename(this.currentCharacterId);

      this.characterInformation.name = rename ? rename : this.getCharacterName(this.currentCharacterId);

      this.characterInformation.tier = await this.getArenaTier(this.currentCharacterId);

      this.characterInformation.level = Number(await this.getCharacterLevel(this.currentCharacterId)) + 1;

      this.characterInformation.power = await this.getCharacterPower(this.currentCharacterId);

      this.characterInformation.rank = await this.getRankingPointsByCharacter(this.currentCharacterId);

      this.characterInformation.element = formatCharacter(this.currentCharacterId, await this.getCharacter(this.currentCharacterId)).traitName;

      this.entryWager = await this.getEntryWagerByTier(this.characterInformation.tier);

      this.untieredEntryWager = await this.getEntryWagerByTier(0);

      this.withdrawCost = this.entryWager * ((await this.getWithdrawFeePercent()) / 100);

      const weaponAvailability = await Promise.all(this.ownedWeaponIds.map(async (weaponId) => {
        return {
          weaponId,
          isInArena: await this.getIsWeaponInArena(weaponId)
        };
      }));

      this.availableWeaponIds = weaponAvailability.filter(weapon => !weapon.isInArena)
        .map(weapon => weapon.weaponId);

      this.ownedWeaponsWithInformation = await Promise.all(this.ownedWeaponIds.map(async (weaponId) => {
        return {
          weaponId,
          information: await this.getWeaponInformation(weaponId)
        };
      }));

      const shieldAvailability = await Promise.all(this.ownedShieldIds.map(async (shieldId) => {
        return {
          shieldId,
          isInArena: await this.getIsShieldInArena(shieldId)
        };
      }));

      this.availableShieldIds = shieldAvailability.filter(shield => !shield.isInArena)
        .map(shield => shield.shieldId);

      this.ownedShieldsWithInformation = await Promise.all(this.ownedShieldIds.map(async (shieldId) => {
        return {
          shieldId,
          information: await this.getShieldInformation(shieldId)
        };
      }));

      if (await this.getIsCharacterInArena(this.currentCharacterId)) {
        this.isCharacterInArena = true;
      }

      if (await this.getIsCharacterInOldArena(this.currentCharacterId)) {
        this.isCharacterInOldArena = true;
      }

      if (this.isCharacterInArena) {
        const fighter = formatFighter(await this.getFighterByCharacter(this.currentCharacterId));

        this.characterInformation.fullPower = await this.getCharacterFullPower({characterId: this.currentCharacterId, tier: this.characterInformation.tier});
        this.characterInformation.untieredFullPower = await this.getCharacterFullPower({characterId: this.currentCharacterId, tier: 20});

        this.activeWeaponWithInformation = {
          weaponId: fighter.weaponID,
          information: await this.getWeaponInformation(fighter.weaponID)
        };

        if (fighter.useShield) {
          this.activeShieldWithInformation = {
            shieldId: fighter.shieldID,
            information: await this.getShieldInformation(fighter.shieldID)
          };
        }

        const { defenderID, createdAt } = (await this.getMatchByFinder(this.currentCharacterId));

        if (+createdAt) {
          await this.updateOpponentInformation(defenderID);
        } else {
          this.clearOpponentInformation();
        }
      }

      this.tierRewardsPool = await this.getRankingsPoolByTier(this.characterInformation.tier);

      this.untieredRewardsPool = await this.getRankingsPoolByTier(20);

      const tierTopRankersIds = await this.getTierTopCharacters(this.characterInformation.tier);

      const untieredTopRankersIds = await this.getTierTopCharacters(20);

      this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
        const rename = await this.getRename(rankerId);
        return {
          rankerId,
          name: rename ? rename : this.getCharacterName(rankerId),
          rank: await this.getRankingPointsByCharacter(rankerId)
        };
      }));

      this.untieredTopRankers = await Promise.all(untieredTopRankersIds.map(async (rankerId) => {
        const rename = await this.getRename(rankerId);
        return {
          rankerId,
          name: rename ? rename : this.getCharacterName(rankerId),
          rank: await this.getRankingPointsByCharacter(rankerId)
        };
      }));

      const fromBlock = Math.max(await this.web3.eth.getBlockNumber() - 1800, 0);

      const previousDuels = await (await this.getPvpCoreContract()).getPastEvents('DuelFinished', {
        filter: {attacker: this.currentCharacterId},
        toBlock: 'latest',
        fromBlock,
      });

      this.duelHistory = previousDuels.map(duel => {
        return formatDuelResult(duel.returnValues);
      });

      await this.processCharacterKick();
    }

    this.loading = false;
  },

  async updated() {
    await this.updateSecondsBeforeSeason();
  },

  destroyed() {
    if (this.restartEventSubscription && this.restartEventSubscription.id) {
      this.restartEventSubscription.unsubscribe();
    }
  },

  watch: {
    async currentCharacterId(value) {
      this.loading = true;

      await this.updateSecondsBeforeSeason();

      this.$emit('leaveMatchMaking');

      if (value !== null) {
        this.characterInformation.name = this.getCharacterName(value);

        this.characterInformation.tier = await this.getArenaTier(value);

        this.characterInformation.level = Number(await this.getCharacterLevel(value)) + 1;

        this.characterInformation.power = await this.getCharacterPower(value);

        this.characterInformation.rank = await this.getRankingPointsByCharacter(value);

        this.characterInformation.element = formatCharacter(value, await this.getCharacter(value)).traitName;

        this.entryWager = await this.getEntryWagerByTier(this.characterInformation.tier);

        this.untieredEntryWager = await this.getEntryWagerByTier(0);

        this.withdrawCost = this.entryWager * ((await this.getWithdrawFeePercent()) / 100);

        const weaponAvailability = await Promise.all(this.ownedWeaponIds.map(async (weaponId) => {
          return {
            weaponId,
            isInArena: await this.getIsWeaponInArena(weaponId)
          };
        }));

        this.availableWeaponIds = weaponAvailability.filter(weapon => !weapon.isInArena)
          .map(weapon => weapon.weaponId);

        this.ownedWeaponsWithInformation = await Promise.all(this.ownedWeaponIds.map(async (weaponId) => {
          return {
            weaponId,
            information: await this.getWeaponInformation(weaponId)
          };
        }));

        const shieldAvailability = await Promise.all(this.ownedShieldIds.map(async (shieldId) => {
          return {
            shieldId,
            isInArena: await this.getIsShieldInArena(shieldId)
          };
        }));

        this.availableShieldIds = shieldAvailability.filter(shield => !shield.isInArena)
          .map(shield => shield.shieldId);

        this.ownedShieldsWithInformation = await Promise.all(this.ownedShieldIds.map(async (shieldId) => {
          return {
            shieldId,
            information: await this.getShieldInformation(shieldId)
          };
        }));

        if (await this.getIsCharacterInArena(value)) {
          this.isCharacterInArena = true;
        } else {
          this.isCharacterInArena = false;
        }

        if (await this.getIsCharacterInOldArena(value)) {
          this.isCharacterInOldArena = true;
        } else {
          this.isCharacterInOldArena = false;
        }

        if (this.isCharacterInArena) {
          const fighter = formatFighter(await this.getFighterByCharacter(value));

          this.characterInformation.fullPower = await this.getCharacterFullPower({characterId: value, tier: this.characterInformation.tier});

          this.characterInformation.untieredFullPower = await this.getCharacterFullPower({characterId: value, tier: 20});

          this.activeWeaponWithInformation = {
            weaponId: fighter.weaponID,
            information: await this.getWeaponInformation(fighter.weaponID)
          };

          if (fighter.useShield) {
            this.activeShieldWithInformation = {
              shieldId: fighter.shieldID,
              information: await this.getShieldInformation(fighter.shieldID)
            };
          } else {
            this.activeShieldWithInformation = {
              shieldId: null,
              information: {}
            };
          }

          const { defenderID, createdAt } = (await this.getMatchByFinder(value));

          if (+createdAt) {
            await this.updateOpponentInformation(defenderID);
          } else {
            this.clearOpponentInformation();
          }
        }

        this.tierRewardsPool = await this.getRankingsPoolByTier(this.characterInformation.tier);

        this.untieredRewardsPool = await this.getRankingsPoolByTier(20);

        const tierTopRankersIds = await this.getTierTopCharacters(this.characterInformation.tier);

        const untieredTopRankersIds = await this.getTierTopCharacters(20);

        this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
          return {
            rankerId,
            name: this.getCharacterName(rankerId),
            rank: await this.getRankingPointsByCharacter(rankerId)
          };
        }));

        this.untieredTopRankers = await Promise.all(untieredTopRankersIds.map(async (rankerId) => {
          return {
            rankerId,
            name: this.getCharacterName(rankerId),
            rank: await this.getRankingPointsByCharacter(rankerId)
          };
        }));

        const fromBlock = Math.max(await this.web3.eth.getBlockNumber() - 1800, 0);

        const previousDuels = await (await this.getPvpCoreContract()).getPastEvents('DuelFinished', {
          filter: {attacker: value},
          toBlock: 'latest',
          fromBlock,
        });

        this.duelHistory = previousDuels.map(duel => {
          return formatDuelResult(duel.returnValues);
        });

        await this.processCharacterKick();

        this.isMatchMaking = false;
      }

      this.loading = false;
    }
  }
};
</script>

<style scoped lang="scss">
  .loadingSpinner {
    display: flex;
    height: 3rem;
    width: 3rem;
    margin: 0 auto;
    margin-top: 3rem ;
    animation: spin 1s linear infinite;
    @keyframes spin {
      from {
        transform: rotate(0deg);
      }
      to {
        transform: rotate(360deg);
      }
    }
  }
  .buttonWrapper {
    margin-top: 2rem;
    margin-left: auto;
    margin-right: auto;
    height: 3rem;
    width: 60%;
  }
</style>
