<template>
  <div class="container">
    <div class="stake-icon-wrapper">
      <img src="https://seiyria.com/gameicons-font/svg/two-coins.svg" alt="" class="stake-type-icon">
    </div>
    <h1 class="stake-type-title">{{ stakeTokenName }} for {{ rewardTokenName }}</h1>
    <table class="stake-data-table">
      <tr>
        <td class="bold">
          Stake:
        </td>
        <td class="align-right">
          {{ stakeTokenName }}
        </td>
      </tr>
      <tr>
        <td class="bold">
          Earn:
        </td>
        <td class="align-right">
          {{ rewardTokenName }}
        </td>
      </tr>
      <tr>
        <td class="bold">
          APR:
        </td>
        <td class="align-right">
          {{ apr }}
        </td>
      </tr>
    </table>
    <router-link
      class="stake-select-button button dark-bg-text"
      :to="{ name: 'stake', params: { stakeType } }">
      Select
    </router-link>
  </div>
</template>

<script>
export default {
  props: ['stakeTokenName', 'rewardTokenName', 'stakeType', 'apr']
};
</script>

<style scoped>
.container {
  background: url("../assets/title-bar-bg-better-tiling.png");
  background-color: rgba(0, 0, 0, 0.233);
  background-blend-mode: darken;
  background-repeat: repeat-y;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stake-icon-wrapper {
  width: 5rem;
  height: 5rem;
  background-color: black;
  border-radius: 5rem;
  border: solid currentColor 2px;
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
}

.stake-data-table {
  width: 100%;
  flex-grow: 1;
  padding: 1rem 0;
}

.align-right {
  text-align: right;
}

.stake-select-button {
  height: 3rem;
  width: 8rem;
  text-decoration: none;
  font-size: 1.5rem;
  display: flex;
  justify-content: center;
  align-items: center;
}

.button {
  background-image: url("../assets/title-bar-bg-better-tiling.png");
  background-color: rgba(255, 255, 255, 0);
  background-blend-mode: lighten;
  border: rgba(0, 0, 0, 0.2) outset 4px;
  border-radius: 0.1em;
}

.button:hover:not(:disabled) {
  background-color: rgba(255, 255, 255, 0.1);
  border-color: currentColor;
  cursor: pointer;
}
</style>
