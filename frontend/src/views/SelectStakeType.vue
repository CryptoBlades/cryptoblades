<template>
  <div class="body main-font">
    <h1 class="text-center">{{$t('stake.staking')}}</h1>
    <ul class="stake-select-list">
      <li class="stake-select-item" v-for="e in entries" :key="e.stakeType">
        <stake-selector-item
          :isLoading="e.isLoading"
          :stakeTitle="e.stakeTitle"
          :stakeTokenName="e.stakeTokenName"
          :rewardTokenName="e.rewardTokenName"
          :stakeType="e.stakeType"
          :minimumStakeTime="stakeOverviews[e.stakeType].minimumStakeTime"
          :estimatedYield="estimatedYields[e.stakeType]"
          :rewardsDuration="stakeOverviews[e.stakeType].rewardsDuration"
          :deprecated="e.deprecated"
          :rewardDistributionTimeLeft="stakeOverviews[e.stakeType].rewardDistributionTimeLeft"
          :currentRewardEarned="staking[e.stakeType].currentRewardEarned"
          :totalStaked="staking[e.stakeType].contractBalance"
          :walletBalance="staking[e.stakeType].ownBalance"/>
      </li>
    </ul>
  </div>
</template>

<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import BN from 'bignumber.js';
import _ from 'lodash';
import Events from '../events';
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN });
BN.config({ EXPONENTIAL_AT: 100 });
import StakeSelectorItem from '../components/stake/StakeSelectorItem.vue';
import Vue from 'vue';
import { humanReadableDetailsForStakeTypes, humanReadableDetailsForNftStakeTypes } from '../stake-types';
import { isNftStakeType } from '@/interfaces';


export default Vue.extend({
  components: {
    StakeSelectorItem
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    ...mapState('staking', ['staking', 'stakeOverviews']),
    ...mapGetters('staking', ['availableStakeTypes', 'availableNftStakeTypes']),

    entries() {
      const entries = this.availableStakeTypes.map(stakeType => ({
        stakeType, ...humanReadableDetailsForStakeTypes[stakeType],
        // make the isLoading = true as a default value to set the loader as initial display
        isLoading: true
      }));
      const nftEntires = this.availableNftStakeTypes.map(stakeType => ({
        stakeType, ...humanReadableDetailsForNftStakeTypes[stakeType],
        // make the isLoading = true as a default value to set the loader as initial display
        isLoading: true
      }));

      return entries.concat(nftEntires);
    },

    estimatedYields() {
      return _.fromPairs(
        this.availableStakeTypes.map(stakeType => [
          stakeType,
          this.calculateEstimatedYield(stakeType)
        ]).concat(
          this.availableNftStakeTypes.map(stakeType => [
            stakeType,
            this.calculateEstimatedYield(stakeType)]))
      );
    },
  },

  methods: {
    ...mapActions('staking',['fetchStakeOverviewData']),

    calculateEstimatedYield(stakeType) {
      const rewardRate = this.stakeOverviews[stakeType].rewardRate;
      const totalStaked = this.stakeOverviews[stakeType].totalSupply;
      const rewardsPerDay = BN(rewardRate).multipliedBy(365.24 * 24 * 60 * 60);

      const totalSupply = BN(totalStaked);

      const estYield = rewardsPerDay.dividedBy(totalSupply);

      if(stakeType === 'lp' || stakeType === 'lp2') {
        return estYield.multipliedBy(0.102); // temporary, fetch from pancakeswap instead in the future
      }

      if(isNftStakeType(stakeType)) {
        return estYield.dividedBy(BN(10).pow(18));
      }

      return estYield;
    },

    setIsLoading(stakeType){
      this.entries.forEach((entry) =>{
        if(stakeType === entry.stakeType){
          entry.isLoading = false;
        }
      });
    }
  },

  async mounted() {
    await this.fetchStakeOverviewData();
    Events.$on('setLoading', (stakeType) =>{
      this.setIsLoading(stakeType);
    });
  }
});
</script>

<style scoped>
.body{
  width: clamp(0px, 100%, 1400px);
  margin:0 auto;
}
h1{
  font-family: 'Trajan';
  font-size: 30px/38px Trajan;
  color: #EDCD90;
  margin-bottom: 30px;
}
.stake-select-list {
  list-style: none;
  margin: 0 auto;
  padding: 0;
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
}

.stake-select-item {
  width: clamp(520px, 45%, 650px);
  margin: 1rem;
  border: 1px solid #404857;
  border-radius: 5px;
}

/* Mobile */
@media only screen and (max-width: 768px)  {
  .stake-select-item {
    width: 100%;
    margin: 1rem 0;
  }
}
</style>
