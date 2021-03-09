<template>
  <ul class="link-list">
    <li>
      <router-link :to="{ name: 'plaza' }">Plaza</router-link>
    </li>
    <li>
      <router-link :to="{ name: 'blacksmith' }">Blacksmith</router-link>
    </li>
    <li>
      <router-link :to="{ name: 'combat' }">Combat</router-link>
    </li>
  </ul>
</template>

<script>
export default {};
</script>

<style>
.link-list {
  list-style-type: none;
  padding: 0;
  margin: 0;
  display: flex;
}

.link-list > li {
  margin: 0.5em;
}
</style>
