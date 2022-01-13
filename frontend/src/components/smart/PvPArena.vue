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
import { mapState } from 'vuex';
import PvPArenaPreparation from './PvPArenaPreparation.vue';
import PvPArenaSummary from './PvPArenaSummary.vue';
import PvPArenaMatchMaking from './PvPArenaMatchMaking.vue';
import PvPKickedModal from './PvPKickedModal.vue';
import { getCharacterNameFromSeed } from '../../character-name';
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
        rank: null
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
      }
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),
  },

  methods: {
    async getWeaponInformation(weaponId) {
      return formatWeapon(`${weaponId}`, await this.contracts().Weapons.methods.get(`${weaponId}`).call({ from: this.defaultAccount }));
    },

    async getShieldInformation(shieldId) {
      return formatShield(`${shieldId}`, await this.contracts().Shields.methods.get(`${shieldId}`).call({ from: this.defaultAccount }));
    },

    async handleEnteredArena() {
      this.loading = true;
      this.isCharacterInArena = true;

      const fighter = formatFighter(await this.contracts().PvpArena.methods.fighterByCharacter(this.currentCharacterId).call({ from: this.defaultAccount }));

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
      this.currentRankedSeason = await this.contracts().PvpArena.methods.currentRankedSeason().call({ from: this.defaultAccount });
      this.seasonStartedAt = await this.contracts().PvpArena.methods.seasonStartedAt().call({ from: this.defaultAccount });
      this.seasonDuration = await this.contracts().PvpArena.methods.seasonDuration().call({ from: this.defaultAccount });
      this.secondsBeforeNextSeason = (+this.seasonStartedAt + +this.seasonDuration) - (Math.floor(Date.now() / 1000));
    },

    async updateOpponentInformation(defenderId) {
      this.opponentInformation.id = defenderId;

      this.opponentInformation.name = getCharacterNameFromSeed(defenderId);

      this.opponentInformation.level = await this.contracts().Characters.methods.getLevel(defenderId).call({ from: this.defaultAccount });

      this.opponentInformation.rank = await this.contracts().PvpArena.methods.rankingPointsByCharacter(defenderId)
        .call({ from: this.defaultAccount });

      this.opponentInformation.element = formatCharacter(defenderId, await this.contracts().Characters.methods.get(`${defenderId}`)
        .call({ from: this.defaultAccount })).traitName;

      const fighter = formatFighter(await this.contracts().PvpArena.methods.fighterByCharacter(defenderId).call({ from: this.defaultAccount }));

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
        rank: null
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
      this.characterInformation.rank = await this.contracts().PvpArena.methods.rankingPointsByCharacter(this.currentCharacterId)
        .call({ from: this.defaultAccount });
    },

    handleCloseModal() {
      this.recentlyKicked.characterId = null;
      this.recentlyKicked.kickedBy = null;
    },

    async getKickedEvents(contracts, blockToScanFrom = 'earliest') {
      const kickedEvents = await contracts.PvpArena.getPastEvents('CharacterKicked', {
        filter: { characterID: this.currentCharacterId },
        toBlock: 'latest',
        fromBlock: blockToScanFrom
      });

      return kickedEvents;
    },

    async processCharacterKick() {
      let blockToScanFrom;
      const lastKickedBlock = localStorage.getItem(`${this.currentCharacterId}-lastKickedBlock`);

      if (lastKickedBlock) {
        blockToScanFrom = lastKickedBlock;
      }

      const kickedEvents = await this.getKickedEvents(this.contracts(), blockToScanFrom);

      if (kickedEvents.length && !this.isCharacterInArena) {
        const formattedResult = formatCharacterKickedEvent(kickedEvents[kickedEvents.length - 1].returnValues);
        const lastKickedEventBlockNumber = kickedEvents[kickedEvents.length - 1].blockNumber;

        const key = `${this.currentCharacterId}-lastKickedTime`;

        if (+localStorage.getItem(key) < +formattedResult.timestamp) {
          localStorage.setItem(key, +formattedResult.timestamp);
          localStorage.setItem(`${this.currentCharacterId}-lastKickedBlock`, lastKickedEventBlockNumber);

          this.recentlyKicked.characterId = formattedResult.characterId;
          this.recentlyKicked.kickedBy = formattedResult.kickedBy;
        }
      }
    },

    async listenForSeasonRestart(contracts, initialBlock) {
      let blockToScan = initialBlock;
      let scanning = false;

      this.web3.eth.subscribe('newBlockHeaders', async (_, result) => {
        try {
          if (scanning) {
            return;
          }
          scanning = true;

          const seasonRestartedEvents = await contracts.PvpArena.getPastEvents('SeasonRestarted', {
            fromBlock: blockToScan,
            toBlock: 'latest',
          });

          blockToScan = result.number + 1;

          if (seasonRestartedEvents.length) {
            this.$dialog.notify.success('A new PvP season has begun!');
            await this.updateSecondsBeforeSeason();
          }

          this.tierRewardsPool = await this.contracts().PvpArena.methods.rankingsPoolByTier(this.characterInformation.tier).call({ from: this.defaultAccount });

          const tierTopRankersIds = await this.contracts().PvpArena.methods.getTierTopCharacters(this.currentCharacterId).call({ from: this.defaultAccount });

          this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
            return {
              rankerId,
              name: getCharacterNameFromSeed(rankerId),
              rank: await this.contracts().PvpArena.methods.rankingPointsByCharacter(rankerId).call({ from: this.defaultAccount })
            };
          }));
        } finally {
          scanning = false;
        }
      });
    }
  },

  async created() {
    const currentBlock = await this.web3.eth.getBlockNumber();

    await this.updateSecondsBeforeSeason();

    await this.listenForSeasonRestart(this.contracts(), currentBlock);

    // Note: currentCharacterId can be 0
    if (this.currentCharacterId !== null) {
      this.characterInformation.name = getCharacterNameFromSeed(this.currentCharacterId);

      this.characterInformation.tier = await this.contracts().PvpArena.methods.getArenaTier(this.currentCharacterId).call({ from: this.defaultAccount });

      this.characterInformation.level = await this.contracts().Characters.methods.getLevel(this.currentCharacterId).call({ from: this.defaultAccount });

      this.characterInformation.power = await this.contracts().Characters.methods.getPower(this.currentCharacterId).call({ from: this.defaultAccount });

      this.characterInformation.rank = await this.contracts().PvpArena.methods.rankingPointsByCharacter(this.currentCharacterId)
        .call({ from: this.defaultAccount });

      this.characterInformation.element = formatCharacter(this.currentCharacterId, await this.contracts().Characters.methods.get(`${this.currentCharacterId}`)
        .call({ from: this.defaultAccount })).traitName;

      this.entryWager = await this.contracts().PvpArena.methods.getEntryWager(this.currentCharacterId).call({ from: this.defaultAccount });

      const weaponAvailability = await Promise.all(this.ownedWeaponIds.map(async (weaponId) => {
        return {
          weaponId,
          isInArena: await this.contracts().PvpArena.methods.isWeaponInArena(weaponId).call({ from: this.defaultAccount })
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
          isInArena: await this.contracts().PvpArena.methods.isShieldInArena(shieldId).call({ from: this.defaultAccount })
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

      if (await this.contracts().PvpArena.methods.isCharacterInArena(this.currentCharacterId).call({ from: this.defaultAccount })) {
        this.isCharacterInArena = true;
      }

      if (this.isCharacterInArena) {
        const fighter = formatFighter(await this.contracts().PvpArena.methods.fighterByCharacter(this.currentCharacterId).call({ from: this.defaultAccount }));

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

      this.tierRewardsPool = await this.contracts().PvpArena.methods.rankingsPoolByTier(this.characterInformation.tier).call({ from: this.defaultAccount });

      const tierTopRankersIds = await this.contracts().PvpArena.methods.getTierTopCharacters(this.currentCharacterId).call({ from: this.defaultAccount });

      this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
        return {
          rankerId,
          name: getCharacterNameFromSeed(rankerId),
          rank: await this.contracts().PvpArena.methods.rankingPointsByCharacter(rankerId).call({ from: this.defaultAccount })
        };
      }));

      const previousDuels = await this.contracts().PvpArena.getPastEvents('DuelFinished', {
        filter: {attacker: this.currentCharacterId},
        toBlock: 'latest',
        fromBlock: 0
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

  unmounted() {
    this.web3.eth.clearSubscriptions();
  },

  watch: {
    async currentCharacterId(value) {
      this.loading = true;

      await this.updateSecondsBeforeSeason();

      this.$emit('leaveMatchMaking');

      if (value !== null) {
        this.characterInformation.name = getCharacterNameFromSeed(value);

        this.characterInformation.tier = await this.contracts().PvpArena.methods.getArenaTier(value).call({ from: this.defaultAccount });

        this.characterInformation.level = await this.contracts().Characters.methods.getLevel(value).call({ from: this.defaultAccount });

        this.characterInformation.power = await this.contracts().Characters.methods.getPower(value).call({ from: this.defaultAccount });

        this.characterInformation.rank = await this.contracts().PvpArena.methods.rankingPointsByCharacter(value).call({ from: this.defaultAccount });

        this.characterInformation.element = formatCharacter(value, await this.contracts().Characters.methods.get(`${value}`)
          .call({ from: this.defaultAccount })).traitName;

        this.entryWager = await this.contracts().PvpArena.methods.getEntryWager(this.currentCharacterId).call({ from: this.defaultAccount });

        const weaponAvailability = await Promise.all(this.ownedWeaponIds.map(async (weaponId) => {
          return {
            weaponId,
            isInArena: await this.contracts().PvpArena.methods.isWeaponInArena(weaponId).call({ from: this.defaultAccount })
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
            isInArena: await this.contracts().PvpArena.methods.isShieldInArena(shieldId).call({ from: this.defaultAccount })
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

        if (await this.contracts().PvpArena.methods.isCharacterInArena(value).call({ from: this.defaultAccount })) {
          this.isCharacterInArena = true;
        } else {
          this.isCharacterInArena = false;
        }

        if (this.isCharacterInArena) {
          const fighter = formatFighter(await this.contracts().PvpArena.methods.fighterByCharacter(value).call({ from: this.defaultAccount }));

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

        this.tierRewardsPool = await this.contracts().PvpArena.methods.rankingsPoolByTier(this.characterInformation.tier)
          .call({ from: this.defaultAccount });

        const tierTopRankersIds = await this.contracts().PvpArena.methods.getTierTopCharacters(value).call({ from: this.defaultAccount });

        this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
          return {
            rankerId,
            name: getCharacterNameFromSeed(rankerId),
            rank: await this.contracts().PvpArena.methods.rankingPointsByCharacter(rankerId).call({ from: this.defaultAccount })
          };
        }));

        const previousDuels = await this.contracts().PvpArena.getPastEvents('DuelFinished', {
          filter: {attacker: value},
          toBlock: 'latest',
          fromBlock: 0
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
