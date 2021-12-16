<template>
  <div class="wrapper">
    <nav class="defaultNav">
      <button @click="setTab(0)" :class="tabNumber === 0 && 'active'">
        <img src="../../assets/swordsIcon.svg"/>
        <span>Arena</span>
      </button>
      <button @click="setTab(1)" :class="tabNumber === 1 && 'active'">
        <img src="../../assets/crownIcon.svg" />
        <span>Leaderboard</span>
      </button>
      <button @click="setTab(2)" :class="tabNumber === 2 && 'active'">
        <img src="../../assets/crownIcon.svg" />
        <span>Rewards</span>
      </button>
    </nav>
  </div>
</template>

<script>
export default {
  props: {
    tabNumber: {
      default: 0
    }
  },

  methods: {
    setTab(tabNumber) {
      this.$emit('changeTab', tabNumber);
    }
  }
};
</script>

<style scoped lang="scss">
.wrapper {
  display: flex;
  margin-bottom: 2rem;
  border-bottom: 1px solid #363636;
  .defaultNav {
    display: flex;
  }
  button {
    display: flex;
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
    align-items: center;
    vertical-align: middle;
    color: #b4b0a7;
    font-size: 0.875rem;
    line-height: 1.25rem;
    border-bottom: 2px solid transparent;
    border-right: none;
    border-left: none;
    border-top: none;
    background-color: transparent;
    img {
      width: 1rem;
      height: 1rem;
      margin-right: 0.5rem;
    }
    span {
      font-family: 'Roboto';
    }
    :hover {
      cursor: pointer;
    }
    &.active {
      color: #ffffff;
      border-bottom: 2px solid #edcd90;
    }
  }
  button:nth-of-type(2) {
    margin: 0 2.5rem;
  }
}
</style>