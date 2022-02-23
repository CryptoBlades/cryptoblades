<template>
  <div>
    <h1 class="text-center">{{ $t('dustBalanceDisplay.availableDust') }}</h1>
    <div class="dusts-container mt-4">
      <div v-for="rarity in rarities" :key="rarity" class="dust-container text-center"
           :class="singleDust ? '' : 'col-lg-2'">
        <div class="dust">
          {{ $t(`dustBalanceDisplay.dustShortName.${DustRarity[rarity]}`) }}: <span
          class="text-warning text-nowrap">{{ $t(`dustBalanceDisplay.dustPower.${DustRarity[rarity]}`) }}</span>
          <img :src="getDustIcon(rarity)" class="w-100 p-4" alt=""/>
        </div>
        <h1 class="text-center">{{ $t(`dustBalanceDisplay.dustName.${DustRarity[rarity]}`) }}</h1>
        <div class="boxed">
          <h2 class="m-0">{{ getDustAmount(rarity) }}</h2>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapGetters} from 'vuex';
import {DustRarity} from '@/views/Quests.vue';
import lesserDust from '@/assets/dusts/lesserDust.png';
import greaterDust from '@/assets/dusts/greaterDust.png';
import powerfulDust from '@/assets/dusts/powerfulDust.png';


export default Vue.extend({
  props: {
    rarities: {
      type: Array,
      default() {
        return [DustRarity.LESSER, DustRarity.GREATER, DustRarity.POWERFUL];
      },
    },
  },

  data() {
    return {
      DustRarity
    };
  },

  computed: {
    ...mapGetters(['getPowerfulDust', 'getGreaterDust', 'getLesserDust']),

    singleDust() {
      return this.rarities.length === 1;
    },
  },

  methods: {
    getDustAmount(rarity: DustRarity) {
      if (rarity === DustRarity.LESSER) {
        return this.getLesserDust();
      } else if (rarity === DustRarity.GREATER) {
        return this.getGreaterDust();
      } else if (rarity === DustRarity.POWERFUL) {
        return this.getPowerfulDust();
      }
    },

    getDustIcon(rarity: DustRarity) {
      if (rarity === DustRarity.LESSER) {
        return lesserDust;
      } else if (rarity === DustRarity.GREATER) {
        return greaterDust;
      } else if (rarity === DustRarity.POWERFUL) {
        return powerfulDust;
      }
    },
  }
})
;
</script>

<style scoped>
.dusts-container {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 6rem;
}

.dust-container {
  border-radius: 5px;
  cursor: pointer;
}

.dust {
  border-style: dashed;
  border-color: #9e8a57;
  border-radius: 5px;
  cursor: pointer;
}

.boxed {
  border: 1px solid #9e8a57;
  margin: 2em;
}
</style>
