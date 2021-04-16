<template>
  <ul class="link-list bold dark-bg-text">
    <li v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'plaza' }" exact
        ><span>Plaza</span></router-link
      >
    </li>
    <li v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'blacksmith' }"
        ><span>Blacksmith</span></router-link
      >
    </li>
    <li v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'combat' }"><span>Combat</span></router-link>
    </li>
    <li>
      <router-link :to="{ name: 'select-stake-type' }"><span>Stake</span></router-link>
    </li>
  </ul>
</template>

<script lang="ts">
export default {
  inject: ['featureFlagStakeOnly'],
};
</script>

<style scoped>
.link-list {
  list-style-type: none;
  padding: 0;
  margin: 0;
  display: flex;
  font-family: "Roboto", sans-serif;
}

.link-list > li {
  margin: 0;
  height: 100%;
  display: flex;
  align-items: stretch;
  font-size: 1.1rem;
}

a {
  padding: 1.2rem;
  text-decoration: none;
  user-select: none;
  color: inherit;
  background: none;
  display: flex;
  justify-content: center;
  flex-direction: column;
}

a:hover,
a.router-link-active {
  background: rgba(255, 255, 255, 0.15);
}
</style>
