<template>
  <div class="top-bar main-font dark-bg-text">
    <h1 class="app-title">CryptoBlades</h1>

    <view-links class="view-links"></view-links>

    <skill-balance-display />
  </div>
</template>

<script lang="ts">
import ViewLinks from './ViewLinks.vue';
import SkillBalanceDisplay from './smart/SkillBalanceDisplay.vue';

export default {
  components: {
    ViewLinks,
    SkillBalanceDisplay,
  },
};
</script>

<style scoped>
.top-bar {
  background: url("../assets/title-bar-bg-better-tiling-bottom.png") #ffffff9f;
  background-blend-mode: hard-light;
  background-position-y: bottom;
  display: flex;
  align-items: stretch;
  padding: 0 1em;
  height: 3.5rem;
}

.app-title {
  margin: 0;
  margin-right: 1em;
  padding: 0.75rem 0;
  align-self: center;
  user-select: none;
}

.view-links {
  flex-grow: 1;
}
</style>
