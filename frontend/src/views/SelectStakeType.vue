<template>
  <div class="body main-font">
    <ul class="stake-select-list">
      <li class="stake-select-item">
        <stake-selector-item stakeTokenName="SKILL" rewardTokenName="SKILL" stakeType="skill" apr="45%" />
      </li>
      <li class="stake-select-item">
        <stake-selector-item stakeTokenName="SKILL-BNB" rewardTokenName="SKILL" stakeType="lp" apr="75%" />
      </li>
    </ul>
  </div>
</template>

<script>
import StakeSelectorItem from '../components/StakeSelectorItem.vue';

export default {
  components: {
    StakeSelectorItem,
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
  width: 15rem;
  height: 20rem;
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
</style>
