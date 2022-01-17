<template>
  <div class="quest-details d-flex flex-column justify-content-between">
    <div v-if="quest" class="d-flex h-100">
      <div class="quest-info d-flex flex-column justify-content-center">
        <div class="quest-description">
          <span class="font-weight-bold">{{ $t(`quests.rarity.${Rarity[quest.tier]}`) }} quest</span>
          <!--          <span>{{ Array(quest.tier + 1).fill('★').join('') }}</span>-->
          <span>{{
              quest.requirementType === RequirementType.RAID ? $t('quests.do') : $t('quests.burn')
            }} {{ quest.requirementAmount }}x {{
              Array(quest.requirementRarity + 1).fill('★').join('')
            }} {{ $t(`quests.requirement.${RequirementType[quest.requirementType]}`) }}</span>
        </div>
        <div class="d-flex justify-content-center p-3">
          <nft-icon v-if="quest.requirementType === RewardType.WEAPON" :isDefault="true" :nft="{ type: 'weapon' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon v-else-if="quest.requirementType === RewardType.JUNK" :isDefault="true" :nft="{ type: 'junk' }"/>
          <nft-icon v-else-if="quest.requirementType === RewardType.DUST && quest.requirementRarity === Rarity.COMMON"
                    :isDefault="true" :nft="{ type: 'lbdust' }"/>
          <nft-icon v-else-if="quest.requirementType === RewardType.DUST && quest.requirementRarity === Rarity.UNCOMMON"
                    :isDefault="true" :nft="{ type: '4bdust' }"/>
          <nft-icon v-else-if="quest.requirementType === RewardType.DUST && quest.requirementRarity === Rarity.RARE"
                    :isDefault="true" :nft="{ type: '5bdust' }"/>
        </div>
        <div class="quest-progress">
          <strong class="quest-progress-text">{{ questData.progress || 0 }} / {{ quest.requirementAmount }}</strong>
          <b-progress class="reputation-progress" :max="quest.requirementAmount" :value="questData.progress"
                      variant="primary"/>
        </div>
      </div>
      <div class="reward-info d-flex flex-column justify-content-center">
        <div class="quest-description">
          <span class="font-weight-bold">Reward</span>
          <span>{{ quest.reputationAmount }} {{ $t('quests.reputation') }}</span>
          <span>{{ quest.rewardAmount }}x <span>{{
              Array(quest.rewardRarity + 1).fill('★').join('')
            }}</span> {{ $t(`quests.reward.${RewardType[quest.rewardType]}`) }}</span>
        </div>
        <div class="d-flex justify-content-center p-3">
          <nft-icon v-if="quest.rewardType === RewardType.WEAPON" :isDefault="true" :nft="{ type: 'weapon' }"
                    :stars="quest.rewardRarity + 1"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.JUNK" :isDefault="true" :nft="{ type: 'junk' }"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.COMMON"
                    :isDefault="true" :nft="{ type: 'lbdust' }"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.UNCOMMON"
                    :isDefault="true" :nft="{ type: '4bdust' }"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.RARE"
                    :isDefault="true" :nft="{ type: '5bdust' }"/>
        </div>
        <!--        <nft-icon :isDefault="true" :nft="{ type: 'trinket' }"/>-->
        <!--        <nft-icon :isDefault="true" :nft="{ type: 'secret' }"/>-->
      </div>
    </div>
    <div class="d-flex">
      <b-button variant="primary" class="flex-1" :disabled="quest.requirementType === RequirementType.RAID"
                @click="submit">
        <!--      || questCanBeCompleted-->
        {{ $t('quests.submit') }}
      </b-button>
      <b-button v-if="questCanBeCompleted" variant="primary" class="flex-1" @click="complete">
        {{ $t('quests.complete') }}
      </b-button>
      <b-button v-else variant="primary" class="flex-1" @click="skip">
        {{ $t('quests.skip') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {PropType} from 'vue/types/options';
import {QuestData} from '@/views/Quests.vue';
import NftIcon from '@/components/NftIcon.vue';

export enum RequirementType {
  NONE, WEAPON, JUNK, DUST, RAID
}

export enum RewardType {
  NONE, WEAPON, JUNK, DUST
}

export enum Rarity {
  COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

export interface Quest {
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

interface Data {
  quest: Quest | undefined;
  questCanBeCompleted: boolean;
}

export default Vue.extend({
  components: {NftIcon},

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


  computed: {},

  methods: {
    ...mapActions(['getCharacterQuestData', 'getQuestData', 'skipQuest', 'completeQuest']) as StoreMappedActions,

    async skip() {
      await this.skipQuest({characterID: this.characterId});
    },

    async complete() {
      await this.completeQuest({characterID: this.characterId});
    },

    submit() {
      this.$root.$emit('quest-submission-modal', this.quest, this.characterId);
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

.flex-1,
.quest-info,
.reward-info {
  flex: 1;
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
  width: 100%;
}
</style>
