<template>
  <div class="quest-reward-display gap-3">
    <span class="reward-title">{{ $t('quests.reward') }}:</span>
    <div class="d-flex align-items-center gap-2" :key="quest.id">
      <QuestComponentIcon :quest="quest" isReward/>
      <QuestComponentIcon :quest="quest" isReputation/>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RewardType} from '@/views/Quests.vue';
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
      RewardType,
      Rarity,
    };
  },
});
</script>

<style scoped>
.quest-reward-display {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.reward-title {
  font: normal normal normal 16px/18px Arial;
  color: #B4B0A7;
}
</style>
