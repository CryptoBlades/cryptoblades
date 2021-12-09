<template>
  <div>
    <div v-if="loading">
      LOADING!
    </div>

    <div v-if="!loading">
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
        v-if="isCharacterInArena"
        :tierRewardsPool="tierRewardsPool"
        :tierTopRankers="tierTopRankers"
        :characterInformation="characterInformation"
        :activeWeaponWithInformation="activeWeaponWithInformation"
        :activeShieldWithInformation="activeShieldWithInformation"
      />
      <pvp-arena-matchmaking v-if="false" />
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import PvPArenaPreparation from './sub-components/PvPArenaPreparation.vue';
import PvPArenaSummary from './sub-components/PvPArenaSummary.vue';
import PvPArenaMatchMaking from './sub-components/PvPArenaMatchMaking.vue';
import { getCharacterNameFromSeed } from '../../../../character-name';
import { weaponFromContract as formatWeapon } from '../../../../contract-models';
import { shieldFromContract as formatShield } from '../../../../contract-models';
import { pvpFighterFromContract as formatFighter } from '../../../../contract-models';

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
        rank: null
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

    handleEnteredArena() {
      this.isCharacterInArena = true;
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

        this.activeShieldWithInformation = {
          shieldId: fighter.shieldID,
          information: await this.getShieldInformation(fighter.shieldID)
        };
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
    }

    this.loading = false;
  },

  watch: {
    async currentCharacterId(value) {
      this.loading = true;

      if (value !== null) {
        this.characterInformation.name = getCharacterNameFromSeed(value);

        this.characterInformation.tier = await this.contracts().PvpArena.methods.getArenaTier(value).call({ from: this.defaultAccount });

        this.characterInformation.level = await this.contracts().Characters.methods.getLevel(value).call({ from: this.defaultAccount });

        this.characterInformation.power = await this.contracts().Characters.methods.getPower(value).call({ from: this.defaultAccount });

        this.characterInformation.rank = await this.contracts().PvpArena.methods.getCharacterRankingPoints(value).call({ from: this.defaultAccount });

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

          this.activeShieldWithInformation = {
            shieldId: fighter.shieldID,
            information: await this.getShieldInformation(fighter.shieldID)
          };
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
      }

      this.loading = false;
    }
  }
};
</script>
