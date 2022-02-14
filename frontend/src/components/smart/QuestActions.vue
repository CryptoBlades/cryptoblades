<template>
  <div class="quest-actions-display gap-2 p-2">
    <b-button v-if="character.quest.id === 0" :disabled="isLoading" variant="primary" @click="request">
      {{ $t('quests.requestQuest') }}
    </b-button>
    <b-button v-else-if="questCanBeCompleted" :disabled="isLoading" variant="primary" class="flex-1"
              @click="complete" :id="character.id" :key="character.id">
      {{ $t('quests.complete') }}
    </b-button>
    <b-button v-if="quest.requirementType !== RequirementType.RAID && !questCanBeCompleted"
              :disabled="isLoading" variant="primary"
              class="flex-1" @click="submit">
      {{ $t('quests.submit') }}
    </b-button>
    <b-button v-if="!questCanBeCompleted" variant="primary" class="flex-1" @click="skip"
              :disabled="(!freeSkip && !hasStaminaToSkip) || isLoading">
      {{ freeSkip ? $t('quests.freeSkip') : $t('quests.skip', {staminaCost: skipQuestStaminaCost}) }}
      <Hint v-if="!freeSkip && !hasStaminaToSkip" class="hint" :text="$t('quests.cannotSkipTooltip')"/>
    </b-button>
    <span v-if="nextFreeSkipTime && character.quest.id !== 0 && !questCanBeCompleted">{{
        $t('quests.freeSkipResetsIn', {time: nextFreeSkipTime})
      }}</span>
    <QuestSubmissionModal :showModal="showSubmissionModal" :character="character"
                          @close-submission-modal="onCloseSubmissionModal"/>

    <b-modal v-model="showQuestCompleteModal" ok-only class="centered-modal" :title="$t('quests.questComplete')"
             @hide="onHideRewardsModal">
      <div v-if="isLoading">
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
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
import {Nft} from '../../interfaces/Nft';
import Hint from '@/components/Hint.vue';
import QuestSubmissionModal from '@/components/smart/QuestSubmissionModal.vue';
import QuestReward from '@/components/smart/QuestReward.vue';
import {mapActions} from 'vuex';
import {NftIdType} from './NftList.vue';
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
      RequirementType,
      RewardType,
      Rarity,
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
      'requestQuest',
      'getSkipQuestStaminaCost',
      'completeQuest',
      'nextFreeSkip',
    ]),

    submit() {
      this.isLoading = true;
      this.showSubmissionModal = true;
    },

    onCloseSubmissionModal() {
      this.showSubmissionModal = false;
      this.isLoading = false;
      this.$emit('refresh-quest-data');
    },

    onHideRewardsModal() {
      this.$emit('refresh-quest-data');
    },

    async skip() {
      try {
        this.isLoading = true;
        await this.skipQuest({characterID: this.character.id});
        await this.refreshSkipQuestData();
        this.$emit('refresh-quest-data');
      } finally {
        this.isLoading = false;
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
      }
    },

    async request() {
      try {
        this.isLoading = true;
        await this.requestQuest({characterID: this.character.id});
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
  },

  async mounted() {
    this.isLoading = true;
    if (!this.refreshQuestTemplates) {
      await this.refreshSkipQuestData();
    }
    this.isLoading = false;
  },

  beforeDestroy() {
    if (this.freeSkipCheckInterval) {
      clearInterval(this.freeSkipCheckInterval);
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
