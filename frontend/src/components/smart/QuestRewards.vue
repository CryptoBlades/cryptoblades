<template>
  <div class="quest-reward-display gap-3">
    <span class="reward-title">{{ $t('quests.reward') }}</span>
    <div class="d-flex align-items-center gap-2 flex-wrap" :key="quest.id">
      <QuestComponentIcon :questItemType="quest.rewardType" :amount="quest.rewardAmount"
                          :rarity="quest.rewardRarity" :externalAddress="quest.rewardExternalAddress"/>
      <QuestComponentIcon v-if="quest.reputationAmount > 0"
        :questItemType="QuestItemType.REPUTATION" :amount="quest.reputationAmount"/>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import { Quest } from '@/interfaces';
import { QuestItemType } from '@/enums/Quest';
import QuestComponentIcon from './QuestComponentIcon.vue';

export default Vue.extend({
  components: {QuestComponentIcon},
  props: {
    quest: {
      type: Object as PropType<Quest>,
      required: true,
    },
  },

  data() {
    return {
      QuestItemType,
    };
  },
});
</script>

<style scoped>
.quest-reward-display {
  display: flex;
  flex-direction: column;
}

.reward-title {
  font: normal normal normal 16px/18px Arial;
  color: #B4B0A7;
}

.quest-reward-display {
    align-items: center;
  }

</style>
