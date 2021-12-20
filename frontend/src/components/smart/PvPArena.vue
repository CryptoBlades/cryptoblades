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
        @leaveArena="leaveArena"
      />
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import PvPArenaPreparation from './PvPArenaPreparation.vue';
import PvPArenaSummary from './PvPArenaSummary.vue';
import PvPArenaMatchMaking from './PvPArenaMatchMaking.vue';
import { getCharacterNameFromSeed } from '../../character-name';
import { weaponFromContract as formatWeapon } from '../../contract-models';
import { shieldFromContract as formatShield } from '../../contract-models';
import { pvpFighterFromContract as formatFighter } from '../../contract-models';
import { characterFromContract as formatCharacter } from '../../contract-models';
import { duelResultFromContract as formatDuelResult } from '../../contract-models';

export default {
  components: {
    'pvp-arena-preparation': PvPArenaPreparation,
    'pvp-arena-summary': PvPArenaSummary,
    'pvp-arena-matchmaking': PvPArenaMatchMaking
  },

  data() {
    return {
      loading: true,
      isCharacterInArena: false,
      entryWager: null,
      isMatchMaking: false,
      tierRewardsPool: null,
      tierTopRankers: [],
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
      duelHistory: []
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),
  },

  methods: {
    async getWeaponInformation(weaponId) {
      const { element, stars } = formatWeapon(`${weaponId}`, await this.contracts().Weapons.methods.get(`${weaponId}`).call({ from: this.defaultAccount }));

      return {
        element,
        stars
      };
    },

    async getShieldInformation(shieldId) {
      const { element, stars } = formatShield(`${shieldId}`, await this.contracts().Shields.methods.get(`${shieldId}`).call({ from: this.defaultAccount }));

      return {
        element,
        stars
      };
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
      this.$emit('leaveMatchMaking');
    },

    async updateOpponentInformation(defenderId) {
      this.opponentInformation.id = defenderId;

      this.opponentInformation.name = getCharacterNameFromSeed(defenderId);

      this.opponentInformation.level = await this.contracts().Characters.methods.getLevel(defenderId).call({ from: this.defaultAccount });

      this.opponentInformation.rank = await this.contracts().PvpArena.methods.getCharacterRankingPoints(defenderId)
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

    kickCharacterFromArena() {
      this.isCharacterInArena = false;
    }
  },

  async created() {
    // Note: currentCharacterId can be 0
    if (this.currentCharacterId !== null) {
      this.characterInformation.name = getCharacterNameFromSeed(this.currentCharacterId);

      this.characterInformation.tier = await this.contracts().PvpArena.methods.getArenaTier(this.currentCharacterId).call({ from: this.defaultAccount });

      this.characterInformation.level = await this.contracts().Characters.methods.getLevel(this.currentCharacterId).call({ from: this.defaultAccount });

      this.characterInformation.power = await this.contracts().Characters.methods.getPower(this.currentCharacterId).call({ from: this.defaultAccount });

      this.characterInformation.rank = await this.contracts().PvpArena.methods.getCharacterRankingPoints(this.currentCharacterId)
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

      this.tierRewardsPool = await this.contracts().PvpArena.methods.getRankingRewardsPool(this.characterInformation.tier).call({ from: this.defaultAccount });

      const tierTopRankersIds = await this.contracts().PvpArena.methods.getTierTopRankers(this.currentCharacterId).call({ from: this.defaultAccount });

      this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
        return {
          rankerId,
          name: getCharacterNameFromSeed(rankerId),
          rank: await this.contracts().PvpArena.methods.getCharacterRankingPoints(rankerId).call({ from: this.defaultAccount })
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
    }

    this.loading = false;
  },

  watch: {
    async currentCharacterId(value) {
      this.loading = true;

      this.$emit('leaveMatchMaking');

      if (value !== null) {
        this.characterInformation.name = getCharacterNameFromSeed(value);

        this.characterInformation.tier = await this.contracts().PvpArena.methods.getArenaTier(value).call({ from: this.defaultAccount });

        this.characterInformation.level = await this.contracts().Characters.methods.getLevel(value).call({ from: this.defaultAccount });

        this.characterInformation.power = await this.contracts().Characters.methods.getPower(value).call({ from: this.defaultAccount });

        this.characterInformation.rank = await this.contracts().PvpArena.methods.getCharacterRankingPoints(value).call({ from: this.defaultAccount });

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
          }
        }

        this.tierRewardsPool = await this.contracts().PvpArena.methods.getRankingRewardsPool(this.characterInformation.tier)
          .call({ from: this.defaultAccount });

        const tierTopRankersIds = await this.contracts().PvpArena.methods.getTierTopRankers(value).call({ from: this.defaultAccount });

        this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
          return {
            rankerId,
            name: getCharacterNameFromSeed(rankerId),
            rank: await this.contracts().PvpArena.methods.getCharacterRankingPoints(rankerId).call({ from: this.defaultAccount })
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