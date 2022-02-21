<template>
  <div class="reward-icon-container">
    <img class="reward-icon" :src="icon" v-b-tooltip="$t(`quests.questItemType.${QuestItemType[this.questItemType]}`)"
         alt=""/>
    <span v-if="questItemType=== QuestItemType.REPUTATION" class="reward-amount">+{{ amount }} Rep</span>
    <span v-else-if="questItemType === QuestItemType.EXPERIENCE">+{{ amount }} Exp</span>
    <span v-else class="reward-amount">x{{ amount }} {{ stars }}</span>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {QuestItemType, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
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
import questItemsInfo from '@/data/questItems.json';

interface QuestItemsInfo {
  questItems: Record<string, Record<string, any>>;
}

interface Data {
  amount: number;
  rarity: Rarity;
  type: RequirementType | RewardType;
  stars: string;
  icon?: string;
  tooltip?: string;
}

export default Vue.extend({
  props: {
    questItemType: {
      type: Number as PropType<QuestItemType>,
      required: true,
    },
    amount: {
      type: Number as PropType<number>,
      required: true,
    },
    rarity: {
      type: Number as PropType<Rarity>,
    },
    externalAddress: {
      type: String as PropType<string>,
    },
  },

  data() {
    return {
      stars: '',
      icon: undefined,
      QuestItemType,
    } as Data;
  },

  methods: {
    typeSupportsStars(): boolean {
      return this.questItemType === QuestItemType.WEAPON
        || this.questItemType === QuestItemType.JUNK
        || this.questItemType === QuestItemType.TRINKET
        || this.questItemType === QuestItemType.SHIELD;
    },
  },

  mounted() {
    if (this.questItemType === QuestItemType.REPUTATION) {
      this.icon = reputation;
    } else if (this.questItemType === QuestItemType.WEAPON) {
      this.icon = sword;
    } else if (this.questItemType === QuestItemType.JUNK) {
      this.icon = junk;
    } else if (this.questItemType === QuestItemType.DUST) {
      if (this.rarity === Rarity.COMMON) {
        this.icon = lesserDust;
      } else if (this.rarity === Rarity.UNCOMMON) {
        this.icon = greaterDust;
      } else if (this.rarity === Rarity.RARE) {
        this.icon = powerfulDust;
      }
    } else if (this.questItemType === QuestItemType.TRINKET) {
      this.icon = trinket;
    } else if (this.questItemType === QuestItemType.SHIELD) {
      this.icon = shield;
    } else if (this.questItemType === RewardType.EXPERIENCE) {
      this.icon = experience;
    } else if (this.questItemType === RequirementType.STAMINA) {
      this.icon = stamina;
    } else if (this.questItemType === QuestItemType.SOUL) {
      this.icon = soul;
    } else if (this.questItemType === RequirementType.RAID) {
      this.icon = raid;
    } else if (this.questItemType === QuestItemType.EXTERNAL || this.questItemType === QuestItemType.EXTERNAL_HOLD) {
      this.icon = (questItemsInfo as QuestItemsInfo).questItems[this.externalAddress].image;
      this.tooltip = (questItemsInfo as QuestItemsInfo).questItems[this.externalAddress].name;
    }
    if (this.typeSupportsStars()) {
      this.stars = Array(this.rarity + 1).fill('★').join('');
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
