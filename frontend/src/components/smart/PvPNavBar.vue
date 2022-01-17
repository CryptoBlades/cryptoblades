<template>
  <div class="wrapper">
    <nav class="defaultNav">
      <button @click="setTab(0)" :class="tabNumber === 0 && 'active'">
        <img src="../../assets/swordsIcon.svg"/>
        <span>
          {{$t('pvp.arena')}}
        </span>
      </button>
      <button @click="setTab(1)" :class="tabNumber === 1 && 'active'">
        <img src="../../assets/crownIcon.svg" />
        <span>
          {{$t('pvp.leaderboard')}}
        </span>
      </button>
      <button @click="setTab(2)" :class="tabNumber === 2 && 'active'">
        <img src="../../assets/crownIcon.svg" />
        <span>
          {{$t('pvp.rewards')}}
          <div class="rewardsIndicator" v-if="hasRewards">
            <div>
              <p>!</p>
            </div>
          </div>
        </span>
      </button>
    </nav>
  </div>
</template>

<script>
export default {
  props: {
    tabNumber: {
      default: 0
    },
    hasRewards: {
      default: false,
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

    .rewardsIndicator {
      display: inline-flex;
      justify-content: center;
      color: black;
    }
    .rewardsIndicator > div {
      background-color: #cec198;
      border-radius: 50%;
      height: 1rem;
      width: 1rem;
      align-items: center;
      justify-content: center;
    }
    .rewardsIndicator > div p {
      display: block;
      color: #000;
      line-height: normal;
      text-align: center;
      font-weight: 500;
}
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