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
        <div class="rewardsButtonInner">
          {{$t('pvp.rewards')}}
          <BIcon icon="exclamation-circle-fill" v-if="hasRewards" class="rewardsIcon"/>
        </div>
      </button>
    </nav>
  </div>
</template>

<script>
import { BIcon } from 'bootstrap-vue';
export default {
  components: {
    BIcon,
  },
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
    .rewardsButtonInner {
      display: flex;
      font-family: 'Roboto';
      .rewardsIcon {
        display: flex;
        margin-left: .5rem;
        color: #edcd90;
        font-size: 1.1rem;
      }
    }
  }
  button {
    display: flex;
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
    align-items: center;
    vertical-align: middle;
    justify-items: center;
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
      display: flex;
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
