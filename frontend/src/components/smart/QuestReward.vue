<template>
  <div class="d-flex flex-column justify-content-center align-items-center flex-1 gap-2">
    <span class="font-weight-bold text-center p-2">{{ $t('quests.reward') }}</span>
    <QuestComponentIcon v-if="reputationAmount" :questItemType="QuestItemType.REPUTATION" :amount="reputationAmount"/>
    <NftList v-if="rewards && rewards.length !== 0" :showGivenNftIdTypes="true" :nftIdTypes="rewards"
             :isReward="true"/>
    <QuestComponentIcon v-else :questItemType="type" :amount="amount" :rarity="rarity"
                        :externalAddress="externalAddress"/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {QuestItemType, Rarity} from '@/views/Quests.vue';
import NftList, {NftIdType} from '@/components/smart/NftList.vue';
import QuestComponentIcon from '@/components/smart/QuestComponentIcon.vue';
import {questItemTypeSupportsStars, questItemTypeSupportsTimesValue} from '../../utils/common';

export default Vue.extend({
  components: {NftList, QuestComponentIcon},

  props: {
    type: {
      type: Number as PropType<QuestItemType>,
    },
    rarity: {
      type: Number as PropType<Rarity>,
    },
    amount: {
      type: Number as PropType<number>,
    },
    rewards: {
      type: Array as PropType<NftIdType[]>,
    },
    reputationAmount: {
      type: Number as PropType<number>,
      default: 0,
    },
    externalAddress: {
      type: String as PropType<string>,
    },
  },

  data() {
    return {
      questItemTypeSupportsTimesValue,
      questItemTypeSupportsStars,
      QuestItemType,
      Rarity,
    };
  },

});
</script>
