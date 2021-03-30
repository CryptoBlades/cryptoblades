<template>
  <ul class="link-list">
    <li>
      <router-link :to="{ name: 'plaza' }" exact><span>Plaza</span></router-link>
    </li>
    <li>
      <router-link :to="{ name: 'blacksmith' }"><span>Blacksmith</span></router-link>
    </li>
    <li>
      <router-link :to="{ name: 'combat' }"><span>Combat</span></router-link>
    </li>
  </ul>
</template>

<script>
export default {};
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
}

a {
  padding: 10px;
  color: white;
  text-decoration: none;
  user-select: none;

  background: none;
  display: flex;
  justify-content: center;
  flex-direction: column;
}

a:hover, a.router-link-active {
  background: rgba(255, 255, 255, 0.25);
}
</style>
