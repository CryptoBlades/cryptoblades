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
    <b-button v-if="character && character.quest.id === 0" :disabled="isLoading" variant="primary request-btn" @click="request">
      <span> {{ $t('quests.requestQuest') }} </span>
    </b-button>
    <b-button v-if="character && character.quest.id === 0" :disabled="isLoading" variant="primary request-btn" @click="showPickableQuestModal=true;">
      <span> Request Special Quest </span>
    </b-button>
    <b-button v-else-if="questCanBeCompleted && !afterDeadline && !deletable" :disabled="isLoading" variant="primary"
              class="flex-1"
              @click="complete()">
      {{ $t('quests.complete') }}
    </b-button>
    <b-button v-if="deletable" variant="primary" class="flex-1 custom-action-btn" @click="deleteQuestTemplate()"
              :disabled="isLoading">
      {{ $t('quests.deleteQuest') }}
    </b-button>
    <b-button
      v-if="quest.requirementType !== RequirementType.RAID && !questCanBeCompleted && !afterDeadline && !deletable"
      :disabled="isLoading" variant="primary"
      class="flex-1 custom-action-btn" @click="submit">
      {{ $t('quests.submit') }}
    </b-button>
    <b-button v-if="character && (!questCanBeCompleted || afterDeadline)" variant="primary" class="flex-1 custom-action-btn" @click="skip"
              :disabled="(!freeSkip && !hasStaminaToSkip) || isLoading">
      {{ freeSkip ? $t('quests.freeSkip') : $t('quests.skip', {staminaCost: skipQuestStaminaCost}) }}
      <Hint v-if="!freeSkip && !hasStaminaToSkip" class="hint" :text="$t('quests.cannotSkipTooltip')"/>
    </b-button>
    <b-form-checkbox size="lg" :checked="pickable" @change="pickable=!pickable" switch v-if="(questCanBeCompleted && !afterDeadline && !deletable) ||
      character && (!questCanBeCompleted || afterDeadline)" >
      <b class="float-left">{{ pickable ? 'Pickable' : 'Random' }}</b>
    </b-form-checkbox>
    <span v-if="nextFreeSkipTime && character && character.quest.id !== 0 && (!questCanBeCompleted || afterDeadline)"
          class="text-center">{{
        $t('quests.freeSkipResetsIn', {time: nextFreeSkipTime})
      }}</span>
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
    <b-modal v-model="showPickableQuestModal" ok-only class="centered-modal" title="Pick your Quest">
      <div v-if="isLoading">
        <i class="fas fa-spinner fa-spin"/>
        {{ $t('quests.loading') }}
      </div>
      <div>
        <b-form inline>
          <label class="mr-sm-2">Special Quest Tier</label>
          <b-form-select class="mt-2 mb-2" v-model="pickableQuestTier">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectQuestTier') }}
            </b-form-select-option>
            <b-form-select-option v-for="tier in tiers" :key="tier" :value="tier">
              {{ $t(`quests.rarityType.${Rarity[tier]}`) }}
            </b-form-select-option>
          </b-form-select>
        </b-form>
          <div v-if="isLoading">
            <i class="fas fa-spinner fa-spin"/>
            {{ $t('quests.loading') }}
          </div>
          <h3 v-else-if="quests.length === 0">
            {{ $t('quests.noQuestTemplatesInSelectedTier') }} </h3>
          <div v-else class="d-flex flex-column gap-3">
            <div v-for="(quest, index) in quests" :key="quest.id" class="quest-row p-3 gap-5">
              <QuestRequirements :quest="quest" :index="index"/>
              <QuestRewards :quest="quest"/>
              <div class="pickBtn-wrapper">
              <b-button class="pickBtn" variant="primary" @click="pickQuest(quest.id)">
                <!-- {{ $t('quests.pickQuest') }} -->
                Pick
              </b-button>
              </div>
            </div>
          </div>
      </div>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RequirementType, RewardType, QuestTemplateType} from '@/views/Quests.vue';
import {Nft} from '../../interfaces/Nft';
import Hint from '@/components/Hint.vue';
import QuestSubmissionModal from '@/components/smart/QuestSubmissionModal.vue';
import QuestReward from '@/components/smart/QuestReward.vue';
import QuestRequirements from '@/components/smart/QuestRequirements.vue';
import QuestRewards from '@/components/smart/QuestRewards.vue';
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
  showPickableQuestModal: boolean;
  pickableQuestTier?: Rarity;
  quests: Quest[];
  pickedQuestId?: number;
}

export default Vue.extend({
  components: {
    Hint,
    QuestSubmissionModal,
    QuestReward,
    QuestRequirements,
    QuestRewards,
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
      showPickableQuestModal: false,
      tiers: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      pickableQuestTier: undefined,
      quests: [],
      pickedQuestId: undefined,
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
  watch: {
    pickableQuestTier(): void {
      this.fetchPickableQuests();
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
    async fetchPickableQuests() {
      try {
        this.isLoading = true;
        this.quests = await this.getQuestTemplates({tier: this.pickableQuestTier! + 20});
      } finally {
        this.isLoading = false;
      }
    },
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
        if (this.pickable) {
          if (!this.pickedQuestId) {
            return this.showPickableQuestModal = true;
          }
          await this.skipQuest({characterID: this.character.id, pickedQuestID: this.pickedQuestId});
        } else {
          await this.skipQuest({characterID: this.character.id});
        }
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
        if(this.questTemplateType === QuestTemplateType.QUEST || this.questTemplateType === QuestTemplateType.PROMO) {
          if (this.pickable) {
            if (!this.pickedQuestId) {
              return this.showPickableQuestModal = true;
            }
            rewards = await this.completeQuest({characterID: this.character.id, pickedQuestID: this.pickedQuestId});
          } else {
            rewards = await this.completeQuest({characterID: this.character.id});
          }
          rewardType = this.quest.rewardType;
          await this.refreshSkipQuestData();
        }
        else if(this.questTemplateType === QuestTemplateType.WALLET){
          rewards = await this.completeWalletQuest({questID: this.quest.id});
          rewardType = this.quest.rewardType;
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
        await this.requestQuest({characterID: this.character.id});
        this.$emit('refresh-quest-data');
      } finally {
        this.isLoading = false;
        this.$forceUpdate();
      }
    },

    async pickQuest(questID: number){
      try {
        this.isLoading = true;
        if (!this.pickedQuestId) {
          this.pickedQuestId = questID;
          return this.showPickableQuestModal = false;
        }
        await this.requestPickableQuest({characterID: this.character.id, questID});
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
  flex: 1;
}
.request-btn{
  width: 30%;
  align-self: flex-end;
}
.quest-row {
  display: flex;
  justify-content: center;
  width: 100%;
  background: #141414;
  border: 1px solid #60583E;
  border-radius: 10px;
  align-items: flex-end;
}
.pickBtn{
  align-self: flex-end;
}
</style>
