<template>
  <div class="reward-icon-container">
    <img class="reward-icon" :src="icon"
         v-b-tooltip="isReputation ? $t('quests.questComponentIconTooltip.REPUTATION')
         : $t(`quests.questComponentIconTooltip.${isReward ? RewardType[type] : RequirementType[type]}`)"
         alt=""/>
    <span v-if="isReputation" class="reward-amount">+{{ amount }} Rep</span>
    <span v-else-if="type === RewardType.EXPERIENCE">+{{ amount }} Exp</span>
    <span v-else class="reward-amount">x{{ amount }} {{ stars }}</span>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
import lesserDust from '@/assets/dusts/lesserDust.png';
import greaterDust from '@/assets/dusts/greaterDust.png';
import powerfulDust from '@/assets/dusts/powerfulDust.png';
import soul from '@/assets/dusts/soulDust.png';
import sword from '@/assets/placeholder/sword-placeholder-1.png';
import junk from '@/assets/junk/junk3.png';
//TODO: Missing icons!
import reputation from '@/assets/reputation.svg';
import stamina from '@/assets/reputation.svg';
import raid from '@/assets/reputation.svg';
//these three^
import experience from '@/assets/experience.png';
import shield from '@/assets/shield2.png';
import trinket from '@/assets/trinkets/trinket1.png';

interface Data {
  amount: number;
  rarity: Rarity;
  type: RequirementType | RewardType;
  stars: string;
  icon?: string;
}

export default Vue.extend({
  props: {
    quest: {
      type: Object as PropType<Quest>,
    },
    isReward: {
      type: Boolean as PropType<boolean>,
      default: false,
    },
    isRequirement: {
      type: Boolean as PropType<boolean>,
      default: false,
    },
    isReputation: {
      type: Boolean as PropType<boolean>,
      default: false,
    },
  },

  data() {
    return {
      amount: 0,
      rarity: 0 as Rarity,
      type: 0 as RewardType | RequirementType,
      stars: '',
      icon: undefined,
      RequirementType,
      RewardType,
      Rarity,
    } as Data;
  },

  mounted() {
    if (this.isReward) {
      this.amount = this.quest.rewardAmount;
      if(this.quest.rewardRarity !== undefined && this.quest.rewardType !== undefined){
        this.rarity = this.quest.rewardRarity;
        this.type = this.quest.rewardType;
      }
    } else if (this.isRequirement) {
      this.amount = this.quest.requirementAmount;
      if(this.quest.requirementRarity !== undefined && this.quest.requirementType !== undefined){
        this.rarity = this.quest.requirementRarity;
        this.type = this.quest.requirementType;
      }
    } else if (this.isReputation) {
      this.amount = this.quest.reputationAmount;
      this.icon = reputation;
    }
    this.stars = Array(this.rarity + 1).fill('★').join('');
    if (this.type === RewardType.WEAPON || this.type === RequirementType.WEAPON) {
      this.icon = sword;
    } else if (this.type === RewardType.JUNK || this.type === RequirementType.JUNK) {
      this.icon = junk;
    } else if (this.type === RewardType.DUST || this.type === RequirementType.DUST) {
      if (this.rarity === Rarity.COMMON) {
        this.icon = lesserDust;
      } else if (this.rarity === Rarity.UNCOMMON) {
        this.icon = greaterDust;
      } else if (this.rarity === Rarity.RARE) {
        this.icon = powerfulDust;
      }
    } else if (this.type === RewardType.TRINKET || this.type === RequirementType.TRINKET) {
      this.icon = trinket;
    } else if (this.type === RewardType.SHIELD || this.type === RequirementType.SHIELD) {
      this.icon = shield;
    } else if (this.type === RewardType.EXPERIENCE) {
      this.icon = experience;
    } else if (this.type === RequirementType.STAMINA) {
      this.icon = stamina;
    } else if (this.type === RewardType.SOUL || this.type === RequirementType.SOUL) {
      this.icon = soul;
    } else if (this.type === RequirementType.RAID) {
      this.icon = raid;
    }
  },

});
</script>

<style scoped>
.reward-icon-container {
  background: #0B0B0B 0 0 no-repeat padding-box;
  border: 1px solid #564B30;
  border-radius: 5px;
  width: 75px;
  height: 75px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.2rem;
}

.reward-icon {
  max-width: 50%;
}

.reward-amount {
  font-size: 0.8rem;
}
</style>
