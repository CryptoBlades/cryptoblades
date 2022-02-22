<template>
  <div class="reward-info d-flex flex-column justify-content-center">
    <div class="quest-description">
      <span class="font-weight-bold">{{ $t('quests.reward') }}</span>
      <span v-if="reputationAmount">{{ reputationAmount }} {{ $t('quests.reputation') }}</span>
      <span v-if="amount">{{ amount }}x <span
        v-if="type !== QuestItemType.EXPERIENCE && type !== QuestItemType.SOUL">{{
          Array(rarity + 1).fill('★').join('')
        }}</span> {{ $t(`quests.rewardType.${QuestItemType[type]}`) }}</span>
    </div>
    <NftList v-if="rewards && rewards.length !== 0" :showGivenNftIdTypes="true" :nftIdTypes="rewards"
             :isReward="true"/>
    <div v-else class="d-flex justify-content-center p-3">
      <nft-icon v-if="type === QuestItemType.WEAPON" :isDefault="true" :nft="{ type: 'weapon' }"
                :stars="rarity + 1"/>
      <nft-icon v-else-if="type === QuestItemType.JUNK" :isDefault="true" :nft="{ type: 'junk' }"
                :stars="rarity + 1"/>
      <nft-icon v-else-if="type === QuestItemType.TRINKET" :isDefault="true" :nft="{ type: 'trinket' }"
                :stars="rarity + 1"/>
      <nft-icon v-else-if="type === QuestItemType.SHIELD" :isDefault="true" :nft="{ type: 'shield' }"
                :stars="rarity + 1"/>
      <nft-icon v-else-if="type === QuestItemType.DUST && rarity === Rarity.COMMON"
                :isDefault="true" :nft="{ type: 'lbdust' }"/>
      <nft-icon v-else-if="type === QuestItemType.DUST && rarity === Rarity.UNCOMMON"
                :isDefault="true" :nft="{ type: '4bdust' }"/>
      <nft-icon v-else-if="type === QuestItemType.DUST && rarity === Rarity.RARE"
                :isDefault="true" :nft="{ type: '5bdust' }"/>
      <nft-icon v-else-if="type === QuestItemType.SOUL" :isDefault="true" :nft="{ type: 'soul' }"/>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {QuestItemType, Rarity} from '@/views/Quests.vue';
import NftIcon from '@/components/NftIcon.vue';
import NftList, {NftIdType} from '@/components/smart/NftList.vue';

export default Vue.extend({
  components: {NftIcon, NftList},

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
  },

  data() {
    return {
      QuestItemType,
      Rarity,
    };
  },

});
</script>

<style scoped>
.reward-info {
  flex: 1;
}

.quest-description {
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
