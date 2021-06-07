<template>
  <div class="top-bar main-font dark-bg-text">
    <h1 class="app-title">
      <img class="logo" src="../assets/logo.png" />
    </h1>

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
  display: flex;
  align-items: stretch;
  padding: 0 1em;
  height: 3.5rem;
  background: rgb(20,20,20);
  background: linear-gradient(90deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
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

.logo {
  max-width: 130px;
  padding-top: 7px;
}
</style>
