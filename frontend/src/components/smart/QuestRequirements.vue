<template>
  <div class="quest-requirement-display gap-3">
    <span class="quest-title">{{ $t('quests.quest') }}</span>
    <div class="d-flex align-items-center gap-3" :key="quest.id">
      <QuestComponentIcon :questItemType="quest.requirementType" :amount="quest.requirementAmount"
                          :rarity="quest.requirementRarity" :externalAddress="quest.requirementExternalAddress"/>
      <div class="d-flex flex-column"><span class="requirement-text">{{
          quest.requirementType === RequirementType.RAID ? $t('quests.do') : $t('quests.submit')
        }} {{ quest.requirementAmount }}<span
          v-if="questItemTypeSupportsTimesValue(quest.requirementType) && !isCurrency">x</span> <span
          v-if="questItemTypeSupportsStars(quest.requirementType)">{{
            Array(quest.requirementRarity + 1).fill('★').join('')
          }} </span>{{ requirementName }} <i
          v-if="quest.requirementType === RequirementType.EXTERNAL || quest.requirementType === RequirementType.EXTERNAL_HOLD"
          :id="`external-hint-${quest.id}-${index}`" class="far fa-question-circle hint"/></span>
        <b-tooltip
          v-if="quest.requirementType === RequirementType.EXTERNAL || quest.requirementType === RequirementType.EXTERNAL_HOLD"
          :target="`external-hint-${quest.id}-${index}`">
          {{ externalTooltip }} <a :href="externalWebsite" target="_blank">{{ externalWebsite }}</a>
        </b-tooltip>
        <span v-if="progress !== undefined" class="progress-text">{{
            $t(`quests.progress`)
          }}: {{ `${progress} / ${quest.requirementAmount}` }}</span>
        <span class="rarity-label text-capitalize" :style="getRarityColor(quest.tier)">
          {{ $t(`quests.rarityType.${Rarity[quest.tier]}`) }}</span>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Quest, QuestItemsInfo, Rarity, RequirementType, RewardType, DustRarity} from '@/views/Quests.vue';
import QuestComponentIcon from './QuestComponentIcon.vue';
import {questItemTypeSupportsStars, questItemTypeSupportsTimesValue} from '@/utils/common';
import {mapActions} from 'vuex';
import questItemsInfo from '@/data/questItems.json';
import i18n from '@/i18n';

interface StoreMappedActions {
  isExternalCurrency(payload: { currencyAddress: string }): Promise<boolean>;
}

export default Vue.extend({
  components: {QuestComponentIcon},
  props: {
    quest: {
      type: Object as PropType<Quest>,
      required: true,
    },
    index: {
      type: Number as PropType<number | string>,
    },
    progress: {
      type: Number,
    },
  },

  data() {
    return {
      isCurrency: false,
      RequirementType,
      RewardType,
      Rarity,
      questItemTypeSupportsTimesValue,
      questItemTypeSupportsStars,
    };
  },

  computed: {
    requirementName(): string {
      if (this.quest.requirementType === RequirementType.EXTERNAL || this.quest.requirementType === RequirementType.EXTERNAL_HOLD) {
        if (this.quest?.requirementExternalAddress === undefined) return '';
        return (questItemsInfo as QuestItemsInfo).questItems[this.quest.requirementExternalAddress].name;
      } else if (this.quest.requirementType === RequirementType.DUST) {
        if(!this.quest.requirementRarity) return '';
        return i18n.t(`quests.dustRarityType.${DustRarity[this.quest.requirementRarity]}`).toString() + ' ' +
          i18n.t(`quests.requirementType.${RequirementType[this.quest.requirementType]}`).toString();
      } else {
        if (!this.quest?.requirementType) return '';
        return i18n.t(`quests.requirementType.${RequirementType[this.quest.requirementType]}`).toString();
      }
    },
    externalTooltip(): string {
      if (!this.quest?.requirementExternalAddress) return '';
      return (questItemsInfo as QuestItemsInfo).questItems[this.quest.requirementExternalAddress].description;
    },
    externalWebsite(): string {
      if (!this.quest?.requirementExternalAddress) return '';
      return (questItemsInfo as QuestItemsInfo).questItems[this.quest.requirementExternalAddress].website;
    },
  },

  methods: {
    ...mapActions([
      'isExternalCurrency',
    ]) as StoreMappedActions,

    getRarityColor(rarity: Rarity) {
      switch (rarity) {
      case Rarity.LEGENDARY: {
        return 'background-color: #D16100';
      }
      case Rarity.EPIC: {
        return 'background-color: #7C1EC1';
      }
      case Rarity.RARE: {
        return 'background-color: #7ba224';
      }
      case Rarity.UNCOMMON: {
        return 'background-color: #3997F5';
      }
      case Rarity.COMMON: {
        return 'background-color: #43506A';
      }
      default: {
        return 'background-color: #43506A';
      }
      }
    }
  },

  async mounted() {
    if (this.quest.requirementExternalAddress) {
      this.isCurrency = await this.isExternalCurrency({currencyAddress: this.quest.requirementExternalAddress});
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
