<template>
  <div class="top-bar main-font dark-bg-text">
    <h1 class="app-title">CryptoBlades</h1>

    <view-links class="view-links"></view-links>

    <skill-balance-display />
  </div>
</template>

<script>
import ViewLinks from "./ViewLinks.vue";
import SkillBalanceDisplay from "./smart/SkillBalanceDisplay.vue";

export default {
  components: {
    ViewLinks,
    SkillBalanceDisplay,
  },
};
</script>

<style scoped>
.top-bar {
  background: rgb(128, 18, 201);
  display: flex;
  align-items: stretch;
  padding: 0 1em;
  height: 64px;
}

.app-title {
  margin: 0;
  margin-right: 1em;
  padding: 12px 0;
  user-select: none;
}

.view-links {
  flex-grow: 1;
}
</style>
