<template>
  <div v-if="isInitialized && (character || deletable || supply)" class="quest-actions-display gap-2 p-2">
    <span v-if="showSupply && supply" class="text-center">
      {{ $t('quests.supplyLeft', {supply}) }}
    </span>
    <span v-if="hasIncomingDeadline" class="text-center">
       {{ $t('quests.questDeadlineIn', {time: deadlineTime}) }}
     </span>
    <span v-else-if="afterDeadline" class="text-center">
      {{ $t('quests.questDeadlineOverCannotBeCompleted') }}
    </span>
    <b-button v-if="character && character.quest.id === 0" :disabled="isLoading" variant="primary" @click="request">
      {{ $t('quests.requestQuest') }}
    </b-button>
    <b-button v-else-if="questCanBeCompleted && !afterDeadline && character" :disabled="isLoading" variant="primary"
              class="flex-1"
              @click="complete" :id="character.id" :key="character.id">
      {{ $t('quests.complete') }}
    </b-button>
    <b-button v-if="deletable" variant="primary" class="flex-1" @click="deleteQuestTemplate()"
              :disabled="isLoading">
      {{ $t('quests.deleteQuest') }}
    </b-button>
    <b-button
      v-if="character && quest.requirementType !== RequirementType.RAID && !questCanBeCompleted && !afterDeadline"
      :disabled="isLoading" variant="primary"
      class="flex-1" @click="submit">
      {{ $t('quests.submit') }}
    </b-button>
    <b-button v-if="character && (!questCanBeCompleted || afterDeadline)" variant="primary" class="flex-1" @click="skip"
              :disabled="(!freeSkip && !hasStaminaToSkip) || isLoading">
      {{ freeSkip ? $t('quests.freeSkip') : $t('quests.skip', {staminaCost: skipQuestStaminaCost}) }}
      <Hint v-if="!freeSkip && !hasStaminaToSkip" class="hint" :text="$t('quests.cannotSkipTooltip')"/>
    </b-button>
    <span v-if="nextFreeSkipTime && character && character.quest.id !== 0 && (!questCanBeCompleted || afterDeadline)"
          class="text-center">{{
        $t('quests.freeSkipResetsIn', {time: nextFreeSkipTime})
      }}</span>
    <QuestSubmissionModal v-if="character" :showModal="showSubmissionModal" :character="character"
                          @close-submission-modal="onCloseSubmissionModal"/>

    <b-modal v-model="showQuestCompleteModal" ok-only class="centered-modal" :title="$t('quests.questComplete')"
             @hide="onHideRewardsModal">
      <div v-if="isLoading">
        <i class="fas fa-spinner fa-spin"/>
        {{ $t('quests.loading') }}
      </div>
      <QuestReward v-else :type="quest.rewardType" :rarity="quest.rewardRarity" :rewards="questRewards"
                   :amount="quest.rewardAmount" :reputationAmount="quest.reputationAmount"/>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
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
}

export default Vue.extend({
  components: {Hint, QuestSubmissionModal, QuestReward},
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
    } as Data;
  },

  computed: {
    questCanBeCompleted(): boolean {
      return this.quest.progress >= this.quest.requirementAmount;
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
      'nextFreeSkip',
      'getQuestDeadline',
      'getQuestSupply',
      'deleteQuest',
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
        this.isLoading = true;
        await this.skipQuest({characterID: this.character.id});
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
        const rewards = await this.completeQuest({characterID: this.character.id});
        const rewardType = this.quest.rewardType;
        await this.refreshSkipQuestData();
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
        await this.requestQuest({characterID: this.character.id});
        this.$emit('refresh-quest-data');
      } finally {
        this.isLoading = false;
        this.$forceUpdate();
      }
    },

    async deleteQuestTemplate() {
      try {
        this.isLoading = true;
        await this.deleteQuest({tier: this.quest.tier, questID: this.quest.id});
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
  flex: 1;
}
</style>
