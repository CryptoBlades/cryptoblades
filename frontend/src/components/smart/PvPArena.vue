<template>
  <div>
    <div v-if="loading">
        <img class="loadingSpinner" src="../../assets/loadingSpinner.svg" />
    </div>
    <div v-else>
      <pvp-arena-preparation
        v-if="!isCharacterInArena"
        :tierRewardsPool="tierRewardsPool"
        :tierTopRankers="tierTopRankers"
        :characterInformation="characterInformation"
        :entryWager="entryWager"
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
        :tierTopRankers="tierTopRankers"
        :characterInformation="characterInformation"
        :activeWeaponWithInformation="activeWeaponWithInformation"
        :activeShieldWithInformation="activeShieldWithInformation"
        :duelHistory="duelHistory"
        :currentRankedSeason="currentRankedSeason"
        :secondsBeforeNextSeason="secondsBeforeNextSeason"
        @enterMatchMaking="handleEnterMatchMaking"
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
import PvPArenaPreparation from './PvPArenaPreparation.vue';
import PvPArenaSummary from './PvPArenaSummary.vue';
import PvPArenaMatchMaking from './PvPArenaMatchMaking.vue';
import PvPKickedModal from './PvPKickedModal.vue';
import { weaponFromContract as formatWeapon } from '../../contract-models';
import { shieldFromContract as formatShield } from '../../contract-models';
import { pvpFighterFromContract as formatFighter } from '../../contract-models';
import { characterFromContract as formatCharacter } from '../../contract-models';
import { duelResultFromContract as formatDuelResult } from '../../contract-models';
import { characterKickedEventFromContract as formatCharacterKickedEvent } from '../../contract-models';


export default {
  inject: ['web3'],

  components: {
    'pvp-arena-preparation': PvPArenaPreparation,
    'pvp-arena-summary': PvPArenaSummary,
    'pvp-arena-matchmaking': PvPArenaMatchMaking,
    'pvp-kicked-modal': PvPKickedModal
  },

  data() {
    return {
      loading: true,
      isCharacterInArena: false,
      entryWager: null,
      isMatchMaking: false,
      tierRewardsPool: null,
      tierTopRankers: [],
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
        power: null
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

    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),
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
      'getCharacterPower',
      'getRankingPointsByCharacter',
      'getRankingsPoolByTier',
      'getTierTopCharacters',
      'getArenaTier',
      'getEntryWager',
      'getIsWeaponInArena',
      'getIsShieldInArena',
      'getIsCharacterInArena',
      'getPvpContract',
      'getRename'
    ]),

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

    async clearOpponentInformation() {
      this.opponentInformation = {
        id: null,
        element: '',
        name: '',
        level: null,
        rank: null,
        power: null
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
      let fromBlock = blockToScanFrom;

      if (!blockToScanFrom) {
        fromBlock = Math.max(await this.web3.eth.getBlockNumber() - 4800, 0);
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

      const kickedEvents = await this.getKickedEvents(await this.getPvpContract(), blockToScanFrom);

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

          const tierTopRankersIds = await this.getTierTopCharacters(this.characterInformation.tier);

          this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
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
    }
  },

  async created() {
    const currentBlock = await this.web3.eth.getBlockNumber();

    await this.updateSecondsBeforeSeason();

    await this.listenForSeasonRestart(await this.getPvpContract(), currentBlock);

    // Note: currentCharacterId can be 0
    if (this.currentCharacterId !== null) {
      const rename = await this.getRename(this.currentCharacterId);

      this.characterInformation.name = rename ? rename : this.getCharacterName(this.currentCharacterId);

      this.characterInformation.tier = await this.getArenaTier(this.currentCharacterId);

      this.characterInformation.level = Number(await this.getCharacterLevel(this.currentCharacterId)) + 1;

      this.characterInformation.power = await this.getCharacterPower(this.currentCharacterId);

      this.characterInformation.rank = await this.getRankingPointsByCharacter(this.currentCharacterId);

      this.characterInformation.element = formatCharacter(this.currentCharacterId, await this.getCharacter(this.currentCharacterId)).traitName;

      this.entryWager = await this.getEntryWager(this.currentCharacterId);

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

      if (this.isCharacterInArena) {
        const fighter = formatFighter(await this.getFighterByCharacter(this.currentCharacterId));

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
      }

      this.tierRewardsPool = await this.getRankingsPoolByTier(this.characterInformation.tier);

      const tierTopRankersIds = await this.getTierTopCharacters(this.characterInformation.tier);

      this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
        const rename = await this.getRename(rankerId);

        return {
          rankerId,
          name: rename ? rename : this.getCharacterName(rankerId),
          rank: await this.getRankingPointsByCharacter(rankerId)
        };
      }));

      const fromBlock = Math.max(await this.web3.eth.getBlockNumber() - 4800, 0);

      const previousDuels = await (await this.getPvpContract()).getPastEvents('DuelFinished', {
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

        this.entryWager = await this.getEntryWager(this.currentCharacterId);

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

        if (this.isCharacterInArena) {
          const fighter = formatFighter(await this.getFighterByCharacter(value));

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
        }

        this.tierRewardsPool = await this.getRankingsPoolByTier(this.characterInformation.tier);

        const tierTopRankersIds = await this.getTierTopCharacters(this.characterInformation.tier);

        this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
          return {
            rankerId,
            name: this.getCharacterName(rankerId),
            rank: await this.getRankingPointsByCharacter(rankerId)
          };
        }));

        const fromBlock = Math.max(await this.web3.eth.getBlockNumber() - 4800, 0);

        const previousDuels = await (await this.getPvpContract()).getPastEvents('DuelFinished', {
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
</style>
