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
      </div>
      <QuestReward :quest="quest"/>
    </div>
    <div v-if="deadline && deadlineTime !== undefined" class="d-flex flex-column align-items-center">
      <span>{{ $t('quests.supplyLeft', {supply}) }}</span>
      <span v-if="deadlineTime">{{ $t('quests.deadline', {deadline: deadlineTime}) }}</span>
      <span v-else class="text-danger">{{ $t('quests.deadlineExpired') }}</span>
    </div>
    <div v-if="!isDisplayOnly">
      <div v-if="!isQuestActionLoading" class="d-flex">
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
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RequirementType} from '@/views/Quests.vue';
import NftIcon from '@/components/NftIcon.vue';
import QuestReward from '@/components/smart/QuestReward.vue';
import {getTimeRemaining} from '../../utils/common';

interface StoreMappedActions {
  deleteQuest(payload: { tier: number, questID: number }): Promise<void>;
}

interface Data {
  isQuestActionLoading: boolean;
}

export default Vue.extend({
  components: {NftIcon, QuestReward},

  props: {
    quest: {
      type: Object as PropType<Quest>,
      required: true,
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
    deadline: {
      type: Number,
    },
    supply: {
      type: Number,
    },
  },

  data() {
    return {
      deadlineCheckInterval: undefined,
      deadlineTime: undefined,
      isQuestActionLoading: false,
      RequirementType,
      Rarity,
    } as Data;
  },

  methods: {
    ...mapActions([
      'deleteQuest',
    ]) as StoreMappedActions,

    async getDeadlineTime() {
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
    },

    async deleteQuestTemplate() {
      if (this.quest.tier !== undefined) {
        try {
          this.isQuestActionLoading = true;
          await this.deleteQuest({tier: this.quest.tier, questID: this.quest.id});
          this.refreshQuestTemplates();
        } finally {
          this.isQuestActionLoading = false;
        }
      }
    },
  },

  mounted() {
    if (this.deadline) {
      this.getDeadlineTime();
    }
  },

  beforeDestroy() {
    if (this.deadlineCheckInterval) {
      clearInterval(this.deadlineCheckInterval);
    }
  },
});
</script>

<style scoped>
.quest-info {
  border-right: 1px solid;
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
