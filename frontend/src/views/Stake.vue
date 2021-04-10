<template>
  <div class="body main-font">
    <staking />
  </div>
</template>

<script>
import Staking from "../components/smart/Staking.vue";

export default {
  components: {
    Staking,
  },
};
</script>

<style scoped>
.body {
  padding: 2em;
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
