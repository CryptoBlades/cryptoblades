<template>
  <div class="quest-details d-flex flex-column justify-content-between">
    <div v-if="quest" class="d-flex h-100">
      <div class="quest-info d-flex flex-column">
        <div class="quest-description">
          <span>{{ $t(`quests.rarity.${Rarity[quest.tier]}`) }} quest</span>
          <span>{{ Array(quest.tier + 1).fill('★').join('') }}</span>
          <span>Do {{ quest.requirementAmount }} {{
              Array(quest.requirementRarity + 1).fill('★').join('')
            }} {{ $t(`quests.requirement.${RequirementType[quest.requirementType]}`) }}</span>
        </div>
        <div>
          <img :src="getFoundersShield" class="quest-goal-image" alt=""/>
        </div>
        <div class="quest-progress">
          <strong class="quest-progress-text">{{ questData.progress || 0 }} / {{ quest.requirementAmount }}</strong>
          <b-progress class="reputation-progress" :max="quest.requirementAmount" :value="questData.progress"
                      variant="primary"/>
        </div>
      </div>
      <div class="reward-info d-flex flex-column">
        <div class="quest-description">
          <span class="font-weight-bold">Reward</span>
          <span>{{ quest.reputationAmount }} {{ $t('quests.reputation') }}</span>
          <span>{{ quest.rewardAmount }}x <span>{{
              Array(quest.rewardRarity + 1).fill('★').join('')
            }}</span> {{ $t(`quests.reward.${RewardType[quest.rewardType]}`) }}</span>
        </div>
        <div>
          <img :src="getFoundersShield" class="quest-goal-image" alt=""/>
        </div>
      </div>
    </div>
    <div class="d-flex">
      <b-button variant="primary" class="flex-grow-1">
        {{ $t('quests.submit') }}
      </b-button>
      <b-button v-if="questCanBeCompleted" variant="primary" class="flex-grow-1" @click="complete">
        {{ $t('quests.complete') }}
      </b-button>
      <b-button v-else variant="primary" class="flex-grow-1" @click="skip">
        {{ $t('quests.skip') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {CartEntry} from '@/components/smart/VariantChoiceModal.vue';
import {mapActions, mapGetters, mapMutations} from 'vuex';
import {Accessors, PropType} from 'vue/types/options';
import foundersShield from '@/assets/shield1.png';
import {QuestData} from '@/views/Quests.vue';

export enum RequirementType {
  NONE, WEAPON, JUNK, DUST, RAID
}

enum RewardType {
  NONE, WEAPON, JUNK, DUST
}

enum Rarity {
  COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

interface Quest {
  id: number;
  tier: Rarity;
  requirementType: RequirementType;
  requirementRarity: Rarity;
  requirementAmount: number;
  rewardType: RewardType;
  rewardRarity: Rarity;
  rewardAmount: number;
  reputationAmount: number;
}

interface StoreMappedActions {
  getCharacterQuestData(payload: { characterId: number }): Promise<{ 0: string, 1: string, 2: string, 3: string, 4: string }>;

  getQuestData(payload: { questId: number }):
  Promise<{ 0: string, 1: string, 2: string, 3: string, 4: string, 5: string, 6: string, 7: string, 8: string, 9: string }>;

  skipQuest(payload: { characterID: string | number }): Promise<void>;

  completeQuest(payload: { characterID: string | number }): Promise<void>;
}

interface StoreMappedMutations {
  clearCartEntries(): void;
}

interface StoreMappedGetters {
  getCartEntries: CartEntry[];
}

interface Data {
  quest: Quest | undefined;
  questCanBeCompleted: boolean;
}

export default Vue.extend({
  components: {},

  props: {
    questData: {
      type: Object as PropType<QuestData>,
      required: true,
    },
    characterId: {
      type: Number,
      required: true,
    }
  },

  data() {
    return {
      quest: undefined,
      questCanBeCompleted: false,
      RequirementType,
      RewardType,
      Rarity,
    } as Data;
  },


  methods: {
    ...mapMutations(['clearCartEntries']) as StoreMappedMutations,
    ...mapActions(['getCharacterQuestData', 'getQuestData', 'skipQuest', 'completeQuest']) as StoreMappedActions,

    async skip() {
      await this.skipQuest({characterID: this.characterId});
    },

    async complete() {
      await this.completeQuest({characterID: this.characterId});
    },
  },

  computed: {
    ...mapGetters(['getCartEntries']) as Accessors<StoreMappedGetters>,

    getFoundersShield() {
      return foundersShield;
    }
  },

  async mounted() {
    const questRaw = await this.getQuestData({questId: this.questData.id});
    this.quest = {
      id: +questRaw[0],
      tier: +questRaw[1] as Rarity,
      requirementType: +questRaw[2] as RequirementType,
      requirementRarity: +questRaw[3] as Rarity,
      requirementAmount: +questRaw[4],
      rewardType: +questRaw[5] as RewardType,
      rewardRarity: +questRaw[6] as Rarity,
      rewardAmount: +questRaw[7],
      reputationAmount: +questRaw[8],
    } as Quest;
    console.log(this.quest);
    this.questCanBeCompleted = this.questData.progress >= this.quest.requirementAmount;
  }

});
</script>

<style scoped>
.quest-info {
  border-right: 1px solid;
}

.quest-progress {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.reputation-progress {
  width: 75%;
}

.xp {
  position: absolute;
  bottom: 30px;
  width: 100%;
  display: flex;
  right: 0;
  flex-direction: column;
  align-items: center;
}

.xp-text {
  position: absolute;
  bottom: -12%;
}

.quest-progress-text {

}

.quest-row,
.quests-container {
  gap: 1rem;
}

.quest-details {
  border: 1px solid;
  border-radius: 5px;
  width: 25rem;
  height: auto;
}

.quest-description {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.quest-goal-image {
  max-width: 100%;
  height: auto;
}
</style>
