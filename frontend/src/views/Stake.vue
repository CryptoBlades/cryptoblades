<template>
  <div class="body main-font">
    <staking class="staking" v-if="stakeType === 'skill' || stakeType === 'lp'" :stakeType="stakeType" />
    <h1 v-else>Unknown stake type, please try again.</h1>
  </div>
</template>

<script lang="ts">
import Staking from '../components/smart/Staking.vue';

export default {
  props: {
    stakeType: {
      type: String,
      validator(type: string) {
        return ['skill', 'lp'].includes(type);
      }
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
