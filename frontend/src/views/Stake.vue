<template>
  <div class="body main-font">
    <staking class="staking" v-if="isKnownStakeType" :stakeType="stakeType" />
    <staking class="staking" v-else-if="isKnownNftStakeType" :stakeType="stakeType" />
    <h1 v-else>{{$t('stake.unknownStakeType')}}</h1>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Staking from '../components/smart/Staking.vue';
import { isNftStakeType, isStakeType } from '../interfaces/State';

export default {
  props: {
    stakeType: {
      type: String,
      validator(type) {
        return isStakeType(type) || isNftStakeType(type);
      }
    }
  },

  computed: {
    ...mapGetters(['availableStakeTypes', 'availableNftStakeTypes']),

    isKnownStakeType() {
      return this.availableStakeTypes.includes(this.stakeType);
    },

    isKnownNftStakeType() {
      return isNftStakeType(this.stakeType);
    }
  },

  components: {
    Staking,
  },
};
</script>

<style scoped>
.body {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.staking {
  padding-top: 2em;
}

</style>
