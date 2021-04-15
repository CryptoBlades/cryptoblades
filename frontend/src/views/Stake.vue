<template>
  <div class="body main-font">
    <staking class="staking" />
  </div>
</template>

<script>
import Staking from '../components/smart/Staking.vue';

export default {
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
