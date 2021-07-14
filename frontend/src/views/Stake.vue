<template>
  <div class="body main-font">
    <staking class="staking" v-if="isKnownStakeType" :stakeType="stakeType" />
    <h1 v-else>Unknown stake type, please try again.</h1>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Staking from '../components/smart/Staking.vue';
import { isStakeType } from '../interfaces/State';

export default {
  props: {
    stakeType: {
      type: String,
      validator(type) {
        return isStakeType(type);
      }
    }
  },

  computed: {
    ...mapGetters(['availableStakeTypes']),

    isKnownStakeType() {
      return this.availableStakeTypes.includes(this.stakeType);
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
