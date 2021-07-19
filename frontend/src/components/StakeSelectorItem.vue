<template>
  <div class="container">
    <div class="stake-icon-wrapper">
      <img src="https://seiyria.com/gameicons-font/svg/two-coins.svg" alt="" class="stake-type-icon">
    </div>
    <h1 class="stake-type-title">{{ stakeTitle }}</h1>
    <div class="table-wrapper">
      <table class="stake-data-table">
        <tr>
          <th class="bold">
            Stake
          </th>
          <td class="align-right">
            {{ stakeTokenName }}
          </td>
        </tr>
        <tr>
          <th class="bold">
            Earn
          </th>
          <td class="align-right">
            {{ rewardTokenName }}
          </td>
        </tr>
        <tr v-if="estimatedYield" title="Estimated yield per year and token.">
          <th class="bold">
            APY
          </th>
          <td class="align-right">
            {{ estimatedYield.multipliedBy(100).toFixed(2) }}%
          </td>
        </tr>
        <tr v-if="minimumStakeTime !== 0">
          <th class="bold">
            Stake locked
          </th>
          <td class="align-right">
            {{ minimumStakeTimeFormatted }}
          </td>
        </tr>
      </table>
    </div>
    <router-link
      class="stake-select-button button dark-bg-text"
      :class="{ deprecated: deprecated }"
      :to="{ name: 'stake', params: { stakeType } }">
        <span v-if="deprecated">Warning</span>
        <span v-if="!deprecated">Select</span>
        <b-icon-question-circle-fill v-if="deprecated"
          v-tooltip="`This stake pool has been deprecated, and should not be staked in anymore.
          You can still pull tokens out or stake at your own risk, but it is not recommended, and it cannot be reversed.`" />
    </router-link>
  </div>
</template>

<script>
import { formatDurationFromSeconds } from '../utils/date-time';

export default {
  props: ['stakeTitle', 'stakeTokenName', 'rewardTokenName', 'stakeType', 'minimumStakeTime', 'estimatedYield', 'deprecated'],

  computed: {
    minimumStakeTimeFormatted() {
      return formatDurationFromSeconds(this.minimumStakeTime);
    }
  }
};
</script>

<style scoped>
.container {
  background: rgb(22, 22, 22);
  background: linear-gradient(180deg, rgba(22, 22, 22, 1) 0%, rgba(16, 17, 17, 1) 100%);
  padding: 1rem;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stake-icon-wrapper {
  width: 5rem;
  height: 5rem;
  padding: 0.5rem;
  box-sizing: border-box;
}

.stake-type-icon {
  width: 100%;
  height: 100%;
  filter: invert(100%);
}

.stake-type-title {
  font-size: 1.2rem;
  padding-bottom: 5px;
  border-bottom: 1px solid #6c5f38;
}

.table-wrapper {
  width: 100%;
  flex-grow: 1;
}

.stake-data-table {
  width: 100%;
  padding: 1rem 0;
}

.align-right {
  text-align: right;
  color: #fff;
}

.stake-select-button {
  height: 3rem;
  width: 8rem;
  text-decoration: none;
  font-size: 1.5rem;
  display: flex;
  justify-content: center;
  align-items: center;
  border: 2px solid #6c5f38;
  border-radius: 0.1em;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
  text-transform: uppercase;
  color: #9e8a57 !important;
}

.stake-select-button.deprecated {
  background: rgb(100, 50, 50);
}

.button:hover:not(:disabled) {
  background-color: rgba(255, 255, 255, 0.1);
  border-color: currentColor;
  cursor: pointer;
}
</style>
