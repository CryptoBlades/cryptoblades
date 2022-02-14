<template>
  <div v-if="characters.length !== 0" class="d-flex flex-wrap quests-container gap-4 p-5">
    <div class="d-flex justify-content-between w-100">
      <span class="quests-title">{{ $t('quests.quest') }}</span>
      <div class="d-flex flex-column gap-2">
        <div class="d-flex justify-content-between gap-4">
          <span class="text-uppercase weekly-progress">{{ $t('quests.weeklyProgress') }}</span>
          <span v-if="nextWeekResetTime" class="next-reset"><img :src="hourglass" class="hourglass-icon" alt=""/> {{
              $t('quests.resetsIn', {time: nextWeekResetTime})
            }}</span>
        </div>
        <div class="quest-progress w-100">
          <div class="quest-progress-bar" role="progressbar"
               :style="`width: calc(${currentWeeklyCompletions/maxWeeklyCompletions*100}% - 8px);`"
               :aria-valuenow="currentWeeklyCompletions"
               aria-valuemin="0" :aria-valuemax="maxWeeklyCompletions">
          </div>
          <!--          <span class="quest-progress-value">{{ `${currentWeeklyCompletions} / ${maxWeeklyCompletions}` }}</span>-->
        </div>
      </div>
    </div>
    <div v-for="character in characters" :key="character.id" class="d-flex w-100">
      <QuestRow :characterId="character.id" :reputationLevelRequirements="reputationLevelRequirements"/>
    </div>
  </div>
  <div v-else-if="isLoading">
    <i class="fas fa-spinner fa-spin"/>
    {{ $t('quests.loading') }}
  </div>
  <div v-else class="m-4 font-weight-bold">
    {{ $t('quests.youNeedToHaveAtLeastOneCharacter') }}
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import {Nft} from '@/interfaces/Nft';
import {Accessors} from 'vue/types/options';
import QuestRow from '@/components/smart/QuestRow.vue';
import hourglass from '@/assets/hourglass.png';
import Events from '@/events';
import {getTimeRemaining} from '@/utils/common';

export interface Quest {
  progress: number;
  type?: RequirementType;
  reputation: number;
  id: number;
  tier?: Rarity;
  requirementType?: RequirementType;
  requirementRarity?: Rarity;
  requirementAmount: number;
  rewardType?: RewardType;
  rewardRarity?: Rarity;
  rewardAmount: number;
  reputationAmount: number;
}

export enum RequirementType {
  NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, STAMINA, SOUL, RAID
}

export enum RewardType {
  NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, EXPERIENCE, SOUL
}

export enum Rarity {
  COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

export enum DustRarity {
  LESSER, GREATER, POWERFUL
}

export enum ReputationTier {
  PEASANT, TRADESMAN, NOBLE, KNIGHT, KING
}

export interface ReputationLevelRequirements {
  level2: number;
  level3: number;
  level4: number;
  level5: number;
}

export interface TierChances {
  common: number;
  uncommon: number;
  rare: number;
  epic: number;
  legendary: number;
}

interface StoreMappedActions {
  fetchCharacters(characterIds: (string | number)[]): Promise<void>;

  getCharacterQuestData(payload: { characterId: string | number }): Promise<Quest>;

  getReputationLevelRequirements(): Promise<ReputationLevelRequirements>;

  nextWeeklyQuestCompletionLimitReset(): Promise<string>;

  getWeeklyCompletionsLimit(): Promise<number>;

  getWeeklyCompletions(): Promise<number>;
}

interface StoreMappedGetters {
  charactersWithIds(ids: (string | number)[]): Nft[];
}

interface Data {
  characters: Nft[];
  reputationLevelRequirements?: ReputationLevelRequirements;
  isLoading: boolean;
  nextWeekResetTime: string;
  nextWeekResetCheckInterval?: ReturnType<typeof setInterval>;
  maxWeeklyCompletions: number;
  currentWeeklyCompletions: number;
}

export default Vue.extend({
  components: {QuestRow},

  props: {
    showCosmetics: {
      type: Boolean,
      default: true
    },
  },

  data() {
    return {
      characters: [] as Nft[],
      reputationLevelRequirements: undefined,
      isLoading: false,
      nextWeekResetTime: '',
      maxWeeklyCompletions: 0,
      currentWeeklyCompletions: 0,
      hourglass,
    } as Data;
  },

  computed: {
    ...mapState(['ownedCharacterIds']),
    ...mapGetters(['charactersWithIds', 'getCharacterCosmetic']) as Accessors<StoreMappedGetters>,
  },

  methods: {
    ...mapActions([
      'fetchCharacters',
      'getCharacterQuestData',
      'getReputationLevelRequirements',
      'nextWeeklyQuestCompletionLimitReset',
      'getWeeklyCompletionsLimit',
      'getWeeklyCompletions',
    ]) as StoreMappedActions,

    async refreshQuestData() {
      try {
        this.isLoading = true;
        this.currentWeeklyCompletions = await this.getWeeklyCompletions();
        this.maxWeeklyCompletions = await this.getWeeklyCompletionsLimit();
        await this.getNextWeekResetTime();
        this.reputationLevelRequirements = await this.getReputationLevelRequirements();
        this.characters = await Promise.all(this.charactersWithIds(this.ownedCharacterIds).filter(Boolean).map(async (character) => {
          character.quest = await this.getCharacterQuestData({characterId: character.id});
          return character;
        }));
      } finally {
        this.isLoading = false;
      }
    },

    async getNextWeekResetTime() {
      const nextWeekResetTimestamp = await this.nextWeeklyQuestCompletionLimitReset();
      if (this.nextWeekResetCheckInterval) {
        clearInterval(this.nextWeekResetCheckInterval);
      }
      this.nextWeekResetCheckInterval = setInterval(() => {
        const {total, days, hours, minutes, seconds} = getTimeRemaining(nextWeekResetTimestamp);
        this.nextWeekResetTime = `${days}d ${hours}h ${minutes}m ${seconds}s`;
        if (total <= 0 && this.nextWeekResetCheckInterval) {
          clearInterval(this.nextWeekResetCheckInterval);
        }
      }, 1000);
    },
  },

  async mounted() {
    await this.refreshQuestData();
    Events.$on('refresh-quest-data', async () => {
      await this.refreshQuestData();
    });
  },

  beforeDestroy() {
    if (this.nextWeekResetCheckInterval) {
      clearInterval(this.nextWeekResetCheckInterval);
    }
  },

  watch: {
    async ownedCharacterIds(characterIds) {
      await this.fetchCharacters(characterIds);
      await this.refreshQuestData();
    }
  },
});
</script>

<style scoped lang="scss">
@import '../styles/character-cosmetics.css';

.quests-container {
  background: transparent url("../../src/assets/questsBackground.png") 0 0 no-repeat padding-box;
}

.quests-title {
  font: normal normal bold 30px/38px Trajan;
  color: #DABE75;
}

.next-reset {
  font: normal normal normal 15px/17px Arial;
  color: #B4B0A7;
}

.hourglass-icon {
  height: 17px;
}

.weekly-progress {
  font: normal normal bold 16px/20px Trajan;
  color: #DABE75;
}

.quest-progress {
  height: 19px;
  background: #070707;
  border: 1px solid #403A2C;
  display: flex;
  align-items: center;
  position: relative;
}

.quest-progress .quest-progress-bar {
  background: #DABE75;
  height: 11px;
  margin: 4px;
}

.quest-progress-value {
  text-align: center;
  font: normal normal normal 10px/11px Arial;
  color: #FFFFFF;
  position: absolute;
  width: 100%;
  font-weight: bold;
}
</style>
