<template>
  <div class="body main-font">
    <ul class="stake-select-list" v-if="stakeOverview">
      <li class="stake-select-item">
        <stake-selector-item
          stakeTokenName="SKILL"
          rewardTokenName="SKILL"
          stakeType="skill"
          :minimumStakeTime="stakeOverview.stakeSkillMinimumStakeTime"
          :estimatedYield="skillStakeEstimatedYield" />
      </li>
      <li class="stake-select-item">
        <stake-selector-item
          stakeTokenName="SKILL-BNB"
          rewardTokenName="SKILL"
          stakeType="lp"
          :minimumStakeTime="stakeOverview.stakeLpMinimumStakeTime"
          :estimatedYield="skillLpEstimatedYield" />
      </li>
    </ul>
    <div class="loading-indicator" v-else>
      <h1>Loading...</h1>
    </div>
  </div>
</template>

<script>
import { mapActions, mapState } from 'vuex';
import BN from 'bignumber.js';
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN });
BN.config({ EXPONENTIAL_AT: 100 });
import StakeSelectorItem from '../components/StakeSelectorItem.vue';

export default {
  components: {
    StakeSelectorItem,
  },

  computed: {
    ...mapState(['stakeOverview']),

    skillStakeEstimatedYield() {
      if(!this.stakeOverview) return null;

      return this.calculateEstimatedYield(
        this.stakeOverview.stakeSkillRewardRate,
        this.stakeOverview.stakeSkillTotalSupply
      );
    },

    skillLpEstimatedYield() {
      if(!this.stakeOverview) return null;

      return this.calculateEstimatedYield(
        this.stakeOverview.stakeLpRewardRate,
        this.stakeOverview.stakeLpTotalSupply
      );
    },
  },

  methods: {
    ...mapActions(['fetchStakeOverviewData']),

    calculateEstimatedYield(rewardRate, totalStaked) {
      const rewardsPerDay = BN(rewardRate).multipliedBy(365.24 * 24 * 60 * 60);

      const totalSupply = BN(totalStaked);

      return rewardsPerDay.dividedBy(totalSupply);
    }
  },

  async mounted() {
    await this.fetchStakeOverviewData();
  }
};
</script>

<style scoped>
.stake-select-list {
  list-style: none;
  margin: 0 auto;
  padding: 0;
  display: flex;
  max-width: 60rem;
  justify-content: center;
  flex-wrap: wrap;
}

.stake-select-item {
  width: 17rem;
  height: 22rem;
  margin: 2rem;
  border-radius: 1rem;
  border: currentColor solid 2px;
  overflow: hidden;
}

.stake-select-item > * {
  width: 100%;
  height: 100%;
  box-sizing: border-box;
}

.loading-indicator {
  min-height: 8rem;
  display: flex;
  justify-content: center;
}

.loading-indicator h1 {
  margin: 3rem;
  display: inline-block;
}
</style>
