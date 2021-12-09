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
      />
      <pvp-arena-matchmaking v-if="isCharacterInArena" />
      <pvp-arena-summary v-if="false" />
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import PvPArenaPreparation from './sub-components/PvPArenaPreparation.vue';
import PvPArenaSummary from './sub-components/PvPArenaSummary.vue';
import PvPArenaMatchMaking from './sub-components/PvPArenaMatchMaking.vue';
import { getCharacterNameFromSeed } from '../../../../character-name';

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
      isMatchMaking: false,
      tierRewardsPool: null,
      tierTopRankers: [],
      characterInformation: {
        tier: null,
        name: '',
        level: null,
        power: null,
        rank: null
      }
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount']),
  },

  methods: {
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

      if (await this.contracts().PvpArena.methods.isCharacterInArena(this.currentCharacterId).call({ from: this.defaultAccount })) {
        this.isCharacterInArena = true;
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

        if (await this.contracts().PvpArena.methods.isCharacterInArena(value).call({ from: this.defaultAccount })) {
          this.isCharacterInArena = true;
        } else {
          this.isCharacterInArena = false;
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
