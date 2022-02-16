<template>
  <div class="quest-requirement-display gap-3">
    <span class="quest-title">{{ $t('quests.quest') }}</span>
    <div class="d-flex align-items-center gap-3" :key="quest.id">
      <QuestComponentIcon :quest="quest" isRequirement/>
      <div class="d-flex flex-column"><span class="requirement-text">{{
          quest.requirementType === RequirementType.RAID ? $t('quests.do') : $t('quests.submit')
        }} {{ quest.requirementAmount }}x <span
          v-if="quest.requirementType !== RequirementType.RAID
          && quest.requirementType !== RequirementType.STAMINA
          && quest.requirementType !== RequirementType.SOUL">{{
            Array(quest.requirementRarity + 1).fill('★').join('')
          }}</span> {{ $t(`quests.requirementType.${RequirementType[quest.requirementType]}`) }}</span>
        <span class="progress-text">{{ $t(`quests.progress`) }}: {{ `${progress} / ${quest.requirementAmount}` }}</span>
        <span class="rarity-label text-capitalize" :style="setRarityColor(Rarity[quest.tier])">
          {{ $t(`quests.rarityType.${Rarity[quest.tier]}`) }}</span>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
import QuestComponentIcon from './QuestComponentIcon.vue';

export default Vue.extend({
  components: {QuestComponentIcon},
  props: {
    quest: {
      type: Object as PropType<Quest>,
      required: true,
    },
    progress: {
      type: Number,
    },
  },

  data() {
    return {
      RequirementType,
      RewardType,
      Rarity,
    };
  },

  methods: {
    setRarityColor(rarity: Rarity) {
      switch (rarity) {
      case Rarity.LEGENDARY: {
        return 'background-color:#D16100';
      }
      case Rarity.EPIC: {
        return 'background-color:#7C1EC1';
      }
      case Rarity.RARE: {
        return 'background-color:#7ba224';
      }
      case Rarity.UNCOMMON: {
        return 'background-color:#3997F5';
      }
      case Rarity.COMMON: {
        return 'background-color:#43506A';
      }
      default: {
        return 'background-color:#43506A';
      }
      }
    }
  }


});
</script>

<style scoped>
.quest-requirement-display {
  display: flex;
  flex-direction: column;
  justify-content: center;
  flex: 1;
}

.rarity-label {
  color: white;
  border-radius: 4px;
  text-align: center;
}

.progress-text {
  font-size: 14px;
  color: #B4B0A7;
}

.requirement-text {
  font-size: 18px;
  color: #DABE75;
}

.quest-title {
  font: normal normal normal 16px/18px Arial;
  color: #B4B0A7;
}
</style>
