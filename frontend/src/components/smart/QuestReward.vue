<template>
  <div class="reward-info d-flex flex-column justify-content-center">
    <div class="quest-description">
      <span class="font-weight-bold">{{ $t('quests.reward') }}</span>
      <span>{{ quest.reputationAmount }} {{ $t('quests.reputation') }}</span>
      <span>{{ quest.rewardAmount }}x <span v-if="quest.rewardType !== RewardType.EXPERIENCE">{{
          Array(quest.rewardRarity + 1).fill('★').join('')
        }}</span> {{ $t(`quests.rewardType.${RewardType[quest.rewardType]}`) }}</span>
    </div>
    <NftList v-if="questRewards && questRewards.length !== 0" :showGivenNftIdTypes="true" :nftIdTypes="questRewards" :isReward="true"/>
    <div v-else class="d-flex justify-content-center p-3">
      <nft-icon v-if="quest.rewardType === RewardType.WEAPON" :isDefault="true" :nft="{ type: 'weapon' }"
                :stars="quest.rewardRarity + 1"/>
      <nft-icon v-else-if="quest.rewardType === RewardType.JUNK" :isDefault="true" :nft="{ type: 'junk' }"
                :stars="quest.rewardRarity + 1"/>
      <nft-icon v-else-if="quest.rewardType === RewardType.TRINKET" :isDefault="true" :nft="{ type: 'trinket' }"
                :stars="quest.rewardRarity + 1"/>
      <nft-icon v-else-if="quest.rewardType === RewardType.SHIELD" :isDefault="true" :nft="{ type: 'shield' }"
                :stars="quest.rewardRarity + 1"/>
      <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.COMMON"
                :isDefault="true" :nft="{ type: 'lbdust' }"/>
      <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.UNCOMMON"
                :isDefault="true" :nft="{ type: '4bdust' }"/>
      <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.RARE"
                :isDefault="true" :nft="{ type: '5bdust' }"/>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RewardType} from '@/views/Quests.vue';
import NftIcon from '@/components/NftIcon.vue';
import NftList, {NftIdType} from '@/components/smart/NftList.vue';

export default Vue.extend({
  components: {NftIcon, NftList},

  props: {
    quest: {
      type: Object as PropType<Quest>,
      required: true,
    },
    questRewards: {
      type: Array as PropType<NftIdType[]>,
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
.reward-info {
  flex: 1;
}

.quest-description {
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
