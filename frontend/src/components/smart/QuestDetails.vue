<template>
  <div class="quest-details d-flex flex-column justify-content-between">
    <div v-if="quest" class="d-flex h-100">
      <div class="quest-info flex-1 d-flex flex-column justify-content-center">
        <div class="quest-description">
          <span
            class="font-weight-bold">{{
              $t(`quests.rarityType.${Rarity[quest.tier]}`)
            }} {{ $t('quests.quest').toLowerCase() }}</span>
          <span class="text-center">{{
              quest.requirementType === RequirementType.RAID ? $t('quests.do') : $t('quests.turnIn')
            }} {{ quest.requirementAmount }}x <span
              v-if="quest.requirementType !== RequirementType.RAID
              && quest.requirementType !== RequirementType.STAMINA && quest.requirementType !== RequirementType.SOUL">{{
                Array(quest.requirementRarity + 1).fill('★').join('')
              }}</span> {{ $t(`quests.requirementType.${RequirementType[quest.requirementType]}`) }}</span>
        </div>
        <div class="d-flex justify-content-center p-3">
          <nft-icon v-if="quest.requirementType === RequirementType.WEAPON" :isDefault="true" :nft="{ type: 'weapon' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon v-else-if="quest.requirementType === RequirementType.JUNK" :isDefault="true" :nft="{ type: 'junk' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon v-else-if="quest.requirementType === RequirementType.TRINKET" :isDefault="true"
                    :nft="{ type: 'trinket' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon v-else-if="quest.requirementType === RequirementType.SHIELD" :isDefault="true"
                    :nft="{ type: 'shield' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon
            v-else-if="quest.requirementType === RequirementType.DUST && quest.requirementRarity === Rarity.COMMON"
            :isDefault="true" :nft="{ type: 'lbdust' }"/>
          <nft-icon
            v-else-if="quest.requirementType === RequirementType.DUST && quest.requirementRarity === Rarity.UNCOMMON"
            :isDefault="true" :nft="{ type: '4bdust' }"/>
          <nft-icon
            v-else-if="quest.requirementType === RequirementType.DUST && quest.requirementRarity === Rarity.RARE"
            :isDefault="true" :nft="{ type: '5bdust' }"/>
          <nft-icon
            v-else-if="quest.requirementType === RequirementType.SOUL" :isDefault="true" :nft="{ type: 'soul' }"/>
        </div>
        <div v-if="!isQuestTemplate && !isDisplayOnly" class="quest-progress">
          <strong>{{ quest.progress }} / {{ quest.requirementAmount }}</strong>
          <b-progress class="quest-progress-bar" :max="quest.requirementAmount" :value="quest.progress"
                      variant="primary"/>
        </div>
      </div>
      <QuestReward :quest="quest"/>
    </div>
    <div v-if="!isDisplayOnly">
      <div v-if="!isQuestTemplate && !isQuestActionLoading" class="d-flex">
        <b-button v-if="quest.requirementType !== RequirementType.RAID && !questCanBeCompleted" variant="primary"
                  class="flex-1" @click="submit">
          {{ $t('quests.submit') }}
        </b-button>
        <b-button v-if="questCanBeCompleted" variant="primary" class="flex-1" @click="complete">
          {{ $t('quests.complete') }}
        </b-button>
        <b-button v-else variant="primary" class="flex-1" @click="skip"
                  :disabled="(!freeSkip && !hasStaminaToSkip) || isStaminaCostLoading">
          {{ freeSkip ? $t('quests.freeSkip') : $t('quests.skip', {staminaCost: skipQuestStaminaCost}) }}
          <hint v-if="!freeSkip && !hasStaminaToSkip" class="hint" :text="$t('quests.cannotSkipTooltip')"/>
        </b-button>
      </div>
      <div v-else-if="isQuestTemplate && !isQuestActionLoading" class="d-flex">
        <b-button variant="primary" class="flex-1" @click="deleteQuestTemplate">
          {{ $t('quests.deleteQuest') }}
        </b-button>
      </div>
      <div v-else-if="isQuestActionLoading" class="d-flex">
        <b-button variant="primary" class="flex-1" :disabled="true">
          <i class="fas fa-spinner fa-spin"/>
          {{ $t('quests.loading') }}
        </b-button>
      </div>
    </div>
    <b-modal v-model="showQuestCompleteModal" ok-only class="centered-modal" :title="$t('quests.questComplete')"
             @hide="Events.$emit('refresh-quest-data');">
      <div v-if="isQuestActionLoading">
        <i class="fas fa-spinner fa-spin"/>
        {{ $t('quests.loading') }}
      </div>
      <QuestReward v-else-if="questRewards.length !== 0" :quest="quest" :questRewards="questRewards"/>
      <QuestReward v-else :quest="quest"/>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
import NftIcon from '@/components/NftIcon.vue';
import Events from '@/events';
import Hint from '@/components/Hint.vue';
import QuestReward from '@/components/smart/QuestReward.vue';
import {NftIdType} from '@/components/smart/NftList.vue';

interface StoreMappedActions {
  hasStaminaToSkipQuest(payload: { characterID: string | number }): Promise<boolean>;

  hasFreeSkip(payload: { characterID: string | number }): Promise<boolean>;

  getSkipQuestStaminaCost(): Promise<number>;

  skipQuest(payload: { characterID: string | number }): Promise<void>;

  completeQuest(payload: { characterID: string | number }): Promise<string[]>;

  deleteQuest(payload: { tier: number, index: number }): Promise<void>;
}

interface Data {
  hasStaminaToSkip: boolean;
  freeSkip: boolean;
  skipQuestStaminaCost: number;
  questRewards: NftIdType[];
  isQuestActionLoading: boolean;
  isStaminaCostLoading: boolean;
  showQuestCompleteModal: boolean;
}

export default Vue.extend({
  components: {NftIcon, Hint, QuestReward},

  props: {
    quest: {
      type: Object as PropType<Quest>,
      required: true,
    },
    isQuestTemplate: {
      type: Boolean,
      default: false,
    },
    isDisplayOnly: {
      type: Boolean,
      default: false,
    },
    questIndex: {
      type: Number,
    },
    refreshQuestTemplates: {
      type: Function,
    },
    characterId: {
      type: Number,
    },
  },

  data() {
    return {
      hasStaminaToSkip: false,
      freeSkip: false,
      skipQuestStaminaCost: 0,
      questRewards: [] as NftIdType[],
      isQuestActionLoading: false,
      isStaminaCostLoading: false,
      showQuestCompleteModal: false,
      RequirementType,
      RewardType,
      Rarity,
      Events,
    } as Data;
  },


  computed: {
    questCanBeCompleted(): boolean {
      return this.quest.progress >= this.quest.requirementAmount;
    },
  },

  methods: {
    ...mapActions([
      'skipQuest',
      'hasStaminaToSkipQuest',
      'hasFreeSkip',
      'getSkipQuestStaminaCost',
      'completeQuest',
      'deleteQuest',
    ]) as StoreMappedActions,

    async skip() {
      try {
        this.isQuestActionLoading = true;
        await this.skipQuest({characterID: this.characterId});
        await this.refreshSkipQuestData();
        Events.$emit('refresh-quest-data');
      } finally {
        this.isQuestActionLoading = false;
      }
    },

    async refreshSkipQuestData() {
      this.hasStaminaToSkip = await this.hasStaminaToSkipQuest({characterID: this.characterId});
      this.freeSkip = await this.hasFreeSkip({characterID: this.characterId});
      try {
        this.isStaminaCostLoading = true;
        this.skipQuestStaminaCost = await this.getSkipQuestStaminaCost();
      } finally {
        this.isStaminaCostLoading = false;
      }
    },

    async complete() {
      try {
        this.isQuestActionLoading = true;
        const rewards = await this.completeQuest({characterID: this.characterId});
        const rewardType = this.quest.rewardType;
        await this.refreshSkipQuestData();

        if (!rewardType || rewardType === RewardType.EXPERIENCE || rewardType === RewardType.DUST || rewardType === RewardType.SOUL) {
          this.showQuestCompleteModal = true;
          return;
        } else {
          this.questRewards = rewards.map(reward => {
            return {type: RewardType[rewardType].toLowerCase(), id: reward} as NftIdType;
          });
          this.showQuestCompleteModal = true;
        }
      } finally {
        this.isQuestActionLoading = false;
      }
    },

    async deleteQuestTemplate() {
      if (this.quest.tier !== undefined) {
        try {
          this.isQuestActionLoading = true;
          await this.deleteQuest({tier: this.quest.tier, index: this.questIndex});
          this.refreshQuestTemplates();
        } finally {
          this.isQuestActionLoading = false;
        }
      }
    },

    submit() {
      Events.$emit('quest-submission-modal', this.quest, this.characterId, this.quest.progress);
    }
  },

  async mounted() {
    if (!this.isQuestTemplate && !this.isDisplayOnly) {
      await this.refreshSkipQuestData();
    }
  },

});
</script>

<style scoped>
.quest-info {
  border-right: 1px solid;
}

.flex-1 {
  flex: 1;
}

.quest-progress {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.quest-progress-bar {
  width: 75%;
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
</style>
