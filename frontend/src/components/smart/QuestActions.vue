<template>
  <div v-if="isInitialized && (showActions || deletable)" class="quest-actions-display gap-2 p-2">
    <span v-if="showSupply && supply" class="text-center">
      {{ $t('quests.supplyLeft', {supply}) }}
    </span>
    <span v-if="hasIncomingDeadline" class="text-center">
       {{ $t('quests.questDeadlineIn', {time: deadlineTime}) }}
     </span>
    <span v-else-if="afterDeadline" class="text-center">
      {{ $t('quests.questDeadlineOverCannotBeCompleted') }}
    </span>
    <b-button v-if="character && character.quest.id === 0" :disabled="isLoading" variant="primary" class="request-quest custom-action-btn" @click="request">
      <span> {{ pickable ? $t('quests.chooseSpecialQuest')  : $t('quests.requestQuest') }} </span>
    </b-button>
    <b-button v-else-if="questCanBeCompleted && !afterDeadline && !deletable" :disabled="isLoading" variant="primary"
              class="flex-1 complete-btn"
              @click="complete()">
      {{ $t('quests.complete') }}
    </b-button>
    <b-button v-if="deletable" variant="primary" class="flex-1 custom-action-btn" @click="deleteQuestTemplate()"
              :disabled="isLoading">
      {{ $t('quests.deleteQuest') }}
    </b-button>
    <b-button
      v-if="canSubmit"
      :disabled="isLoading" variant="primary"
      class="flex-1 custom-action-btn" @click="submit">
      {{ quest.requirementType === RequirementType.EXTERNAL_HOLD ? $t('quests.show') : $t('quests.submit') }}
    </b-button>
    <b-button v-if="character && isOnQuest && (!questCanBeCompleted || afterDeadline)" variant="primary" class="flex-1 custom-action-btn" @click="skip"
              :disabled="!questCanBeSkipped || isLoading">
      {{ freeSkip ? $t('quests.freeSkip') : $t('quests.skip', {staminaCost: skipQuestStaminaCost}) }}
      <Hint v-if="!questCanBeSkipped" class="hint" :text="$t('quests.cannotSkipTooltip')"/>
    </b-button>
    <span v-if="nextFreeSkipTime && character && character.quest.id !== 0 && (!questCanBeCompleted || afterDeadline)"
          class="text-center">{{
        $t('quests.freeSkipResetsIn', {time: nextFreeSkipTime})
      }}
    </span>
    <!-- ADD TOOLTIP HERE -->
    <QuestSubmissionModal v-if="character||quest" :quest="quest" :questTemplateType="questTemplateType" :showModal="showSubmissionModal" :character="character"
                          @close-submission-modal="onCloseSubmissionModal"/>

    <b-modal v-model="showQuestCompleteModal" ok-only class="centered-modal" :title="$t('quests.questComplete')"
             @hide="onHideRewardsModal">
      <div v-if="isLoading">
        <i class="fas fa-spinner fa-spin"/>
        {{ $t('quests.loading') }}
      </div>
      <QuestReward v-else :type="quest.rewardType" :rarity="quest.rewardRarity" :rewards="questRewards"
                   :amount="quest.rewardAmount" :reputationAmount="quest.reputationAmount"
                   :externalAddress="quest.rewardExternalAddress"/>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import { Quest, RewardType } from '@/interfaces';
import {
  Rarity,
  RequirementType,
  QuestTemplateType } from '@/enums/Quest';
import {Nft} from '../../interfaces/Nft';
import Hint from '@/components/Hint.vue';
import QuestSubmissionModal from '@/components/smart/QuestSubmissionModal.vue';
import QuestReward from '@/components/smart/QuestReward.vue';
import {mapActions} from 'vuex';
import {NftIdType} from '@/components/smart/NftList.vue';
import {getTimeRemaining} from '@/utils/common';

interface Data {
  hasStaminaToSkip: boolean;
  isLoading: boolean;
  showSubmissionModal: boolean;
  showQuestCompleteModal: boolean;
  freeSkip: boolean;
  skipQuestStaminaCost: number;
  questRewards: NftIdType[];
  freeSkipCheckInterval?: ReturnType<typeof setInterval>;
  nextFreeSkipTime: string;
  deadlineCheckInterval?: ReturnType<typeof setInterval>;
  deadlineTime: string;
  isLimited: boolean;
  isInitialized: boolean;
  supply: number;
  quests: Quest[];
}

export default Vue.extend({
  components: {
    Hint,
    QuestSubmissionModal,
    QuestReward,
  },
  props: {
    character: {
      type: Object as PropType<Nft>,
    },
    quest: {
      type: Object as PropType<Quest>,
      required: true,
    },
    questIndex: {
      type: Number,
    },
    pickable: {
      type: Boolean,
      default: false
    },
    refreshQuestTemplates: {
      type: Function,
    },
    deletable: {
      type: Boolean,
      default: false,
    },
    showSupply: {
      type: Boolean,
      default: false,
    },
    deadline: {
      type: Number,
    },
    questSupply: {
      type: Number,
    },
    showActions: {
      type: Boolean,
      default: true,
    },
    questTemplateType: {
      type: Number as PropType<QuestTemplateType>,
      required: true,
    },
    pickedQuestId: {
      type: Number as PropType<number>,
      default: 0,
    },
  },

  data() {
    return {
      hasStaminaToSkip: false,
      isLoading: false,
      showSubmissionModal: false,
      showQuestCompleteModal: false,
      freeSkip: false,
      skipQuestStaminaCost: 0,
      questRewards: [] as NftIdType[],
      freeSkipCheckInterval: undefined,
      nextFreeSkipTime: '',
      deadlineCheckInterval: undefined,
      deadlineTime: '',
      isLimited: false,
      isInitialized: false,
      supply: 0,
      RequirementType,
      RewardType,
      Rarity,
      QuestTemplateType,
      quests: [],
    } as Data;
  },

  computed: {
    isOnQuest(): boolean{
      return !!this.quest.id && !!this.quest.requirementAmount;
    },
    questCanBeSkipped(): boolean {
      return this.isOnQuest && (this.freeSkip || this.hasStaminaToSkip);
    },
    questCanBeCompleted(): boolean {
      return this.isOnQuest && (this.quest.progress >= this.quest.requirementAmount && this.quest.requirementAmount !== 0);
    },
    canSubmit(): boolean {
      return this.isOnQuest && this.quest.requirementType !== RequirementType.RAID && !this.afterDeadline && !this.deletable && !this.questCanBeCompleted;
    },
    afterDeadline(): boolean {
      return this.isLimited && !this.deadlineTime;
    },
    hasIncomingDeadline(): boolean {
      return this.isLimited && !!this.deadlineTime;
    },
  },
  methods: {
    ...mapActions([
      'skipQuest',
      'hasStaminaToSkipQuest',
      'hasFreeSkip',
      'requestQuest',
      'getSkipQuestStaminaCost',
      'completeQuest',
      'completeWalletQuest',
      'requestPickableQuest',
      'nextFreeSkip',
      'getQuestDeadline',
      'getQuestSupply',
      'deleteQuest',
      'getQuestTemplates',
    ]),
    submit() {
      this.isLoading = true;
      this.showSubmissionModal = true;
    },

    onCloseSubmissionModal() {
      this.showSubmissionModal = false;
      this.isLoading = false;
      this.$emit('refresh-quest-data');
      this.$forceUpdate();
    },

    onHideRewardsModal() {
      this.$emit('refresh-quest-data');
      this.$forceUpdate();
    },

    async skip() {
      try {
        await this.skipQuest({characterID: this.character.id, pickedQuestID: this.pickedQuestId});
        this.isLoading = true;
        await this.refreshSkipQuestData();
        this.$emit('refresh-quest-data');
      } finally {
        this.isLoading = false;
        this.$forceUpdate();
      }
    },

    async complete() {
      try {
        this.isLoading = true;
        let rewards;
        let rewardType: any;
        if(this.questTemplateType === QuestTemplateType.WALLET) {
          rewards = await this.completeWalletQuest({questID: this.quest.id});
          rewardType = this.quest.rewardType;
        }
        else {
          rewards = await this.completeQuest({characterID: this.character.id, pickedQuestID: this.pickedQuestId});
          rewardType = this.quest.rewardType;
          await this.refreshSkipQuestData();
        }
        if (!rewardType || rewardType === RewardType.EXPERIENCE || rewardType === RewardType.DUST || rewardType === RewardType.SOUL) {
          this.showQuestCompleteModal = true;
          return;
        } else {
          this.questRewards = rewards.map((reward: number) => {
            return {type: RewardType[rewardType].toLowerCase(), id: reward} as NftIdType;
          });
          this.showQuestCompleteModal = true;
        }
      } finally {
        this.isLoading = false;
        this.$forceUpdate();
      }
    },

    async request() {
      try {
        this.isLoading = true;
        if (this.pickedQuestId) {
          await this.requestPickableQuest({characterID: this.character.id, questID: this.pickedQuestId});
        }
        else {
          await this.requestQuest({characterID: this.character.id});
        }
        this.$emit('refresh-quest-data');
      } finally {
        this.isLoading = false;
        this.$forceUpdate();
      }
    },

    async deleteQuestTemplate() {
      try {
        this.isLoading = true;
        await this.deleteQuest({tier: this.quest.tier!+this.questTemplateType, questID: this.quest.id});
        this.$emit('refresh-quest-data');
      } finally {
        this.isLoading = false;
      }
    },

    async refreshSkipQuestData() {
      this.hasStaminaToSkip = await this.hasStaminaToSkipQuest({characterID: this.character.id});
      this.freeSkip = await this.hasFreeSkip({characterID: this.character.id});
      this.skipQuestStaminaCost = await this.getSkipQuestStaminaCost();
      await this.getNextFreeSkipTime();
    },

    async getNextFreeSkipTime() {
      const nextFreeSkipTimestamp = await this.nextFreeSkip();
      if (this.freeSkipCheckInterval) {
        clearInterval(this.freeSkipCheckInterval);
      }
      this.freeSkipCheckInterval = setInterval(() => {
        const {total, hours, minutes, seconds} = getTimeRemaining(nextFreeSkipTimestamp);
        this.nextFreeSkipTime = `${hours}h ${minutes}m ${seconds}s`;
        if (total <= 0 && this.freeSkipCheckInterval) {
          clearInterval(this.freeSkipCheckInterval);
          this.nextFreeSkipTime = '';
          this.freeSkip = true;
        }
      }, 1000);
    },

    async getDeadlineTime() {
      const deadlineTimestamp = +await this.getQuestDeadline({questID: this.quest.id});
      this.isLimited = deadlineTimestamp !== 0;
      if (!deadlineTimestamp) return;
      if (this.deadlineCheckInterval) {
        clearInterval(this.deadlineCheckInterval);
      }
      this.deadlineCheckInterval = setInterval(() => {
        const {total, days, hours, minutes, seconds} = getTimeRemaining(deadlineTimestamp.toString());
        this.deadlineTime = `${days !== '00' ? `${days}d ` : ''} ${hours !== '00' ? `${hours}h ` : ''} ${minutes}m ${seconds}s`;
        if (total <= 0 && this.deadlineCheckInterval) {
          clearInterval(this.deadlineCheckInterval);
          this.deadlineTime = '';
        }
      }, 1000);
    },
  },

  async mounted() {
    if(this.questSupply) {
      this.supply = this.questSupply;
    }
    if (!this.refreshQuestTemplates && this.character) {
      await this.refreshSkipQuestData();
    }
    if (!this.supply && !this.deadline) {
      if (this.showSupply) {
        this.supply = +await this.getQuestSupply({questID: this.quest.id});
      }
      await this.getDeadlineTime();
    } else {
      this.isLimited = true;
      if (this.deadlineCheckInterval) {
        clearInterval(this.deadlineCheckInterval);
      }
      this.deadlineCheckInterval = setInterval(() => {
        const {total, days, hours, minutes, seconds} = getTimeRemaining(this.deadline.toString());
        this.deadlineTime = `${days !== '00' ? `${days}d ` : ''} ${hours !== '00' ? `${hours}h ` : ''} ${minutes}m ${seconds}s`;
        if (total <= 0 && this.deadlineCheckInterval) {
          clearInterval(this.deadlineCheckInterval);
          this.deadlineTime = '';
        }
      }, 1000);
    }
    this.isInitialized = true;
  },

  beforeDestroy() {
    if (this.freeSkipCheckInterval) {
      clearInterval(this.freeSkipCheckInterval);
    }
    if (this.deadlineCheckInterval) {
      clearInterval(this.deadlineCheckInterval);
    }
  },


});
</script>

<style scoped>
.quest-actions-display {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100%;
}
.custom-action-btn{
  font-family: Roboto;
  background: transparent !important;
  border: #EDCD90 1px solid !important;
  color: #FFF !important;
  width: 100%;
  max-height: 50px;
}

.custom-action-btn.request-quest {
  min-height: 50px;
  max-height: 63px;
}

.custom-action-btn:disabled {
  border-color: #FFF !important;
}
.custom-action-btn:not([disabled]):hover{
  border-color: #FFF !important;
}
.complete-btn{
  font-family: Roboto;
  border: #EDCD90 1px solid !important;
  color: #FFF !important;
  width: 100%;
  max-height: 50px;
}
.quest-row {
  display: flex;
  width: 100%;
  background: rgba(0, 9, 26, 0.65);
  border: 1px solid #404857;
  border-radius: 10px;
  align-items: center;
  font-family: Roboto;
  height: clamp(200px, 20vh, 250px);
  justify-content: space-between;
  margin: 10px 0;
  padding: 10px 30px;
}

.quest-row {
    flex-direction: column;
    height: auto;
    gap: 1rem;
  }
</style>
