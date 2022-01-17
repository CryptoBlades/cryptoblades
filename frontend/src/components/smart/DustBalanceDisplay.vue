<template>
  <div :class="singleDust ? '' : 'col-lg-12'">
    <h1 class="text-center">{{ $t('dustBalanceDisplay.availableDust') }}</h1>
    <div class="dusts-container mt-4" :class="singleDust ? 'p-5' : ''">
      <div v-if="rarities.includes(Rarity.COMMON)" class="dust-container text-center"
           :class="singleDust ? '' : 'col-lg-2'">
        <div class="dust">
          LB: <span class="text-warning text-nowrap">{{ $t('dustBalanceDisplay.lesserPower') }}</span>
          <img src="../../assets/dusts/lesserDust.png" class="w-100" alt=""/>
        </div>
        <h1 class="text-center">{{ $t('dustBalanceDisplay.lesser') }}</h1>
        <div class="boxed">
          <h2>{{ getLesserDust() }}</h2>
        </div>
      </div>
      <div v-if="rarities.includes(Rarity.UNCOMMON)" class="dust-container text-center"
           :class="singleDust ? '' : 'col-lg-2'">
        <div class="dust">
          4B: <span class="text-warning text-nowrap">{{ $t('dustBalanceDisplay.greaterPower') }}</span>
          <img src="../../assets/dusts/greaterDust.png" class="w-100" alt=""/>
        </div>
        <h1 class="text-center">{{ $t('dustBalanceDisplay.greater') }}</h1>
        <div class="boxed">
          <h2>{{ getGreaterDust() }}</h2>
        </div>
      </div>
      <div v-if="rarities.includes(Rarity.RARE)" class="dust-container text-center"
           :class="singleDust ? '' : 'col-lg-2'">
        <div class="dust">
          5B: <span class="text-warning text-nowrap">{{ $t('dustBalanceDisplay.powerfulPower') }}</span>
          <img src="../../assets/dusts/powerfulDust.png" class="w-100" alt=""/>
        </div>
        <h1 class="text-center">{{ $t('dustBalanceDisplay.powerful') }}</h1>
        <div class="boxed">
          <h2>{{ getPowerfulDust() }}</h2>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Vue from 'vue';
import {mapGetters} from 'vuex';
import {Rarity} from '@/components/smart/QuestDetails.vue';


export default Vue.extend({
  props: {
    rarities: {
      type: Array,
      default() {
        return [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE];
      },
    },
  },

  data() {
    return {
      Rarity
    };
  },

  computed: {
    ...mapGetters(['getPowerfulDust', 'getGreaterDust', 'getLesserDust']),

    singleDust() {
      return this.rarities.length === 1;
    }
  },
});
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
