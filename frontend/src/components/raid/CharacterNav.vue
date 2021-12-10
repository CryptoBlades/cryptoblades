<template>
  <div class="character-nav">
    <ul>
      <li><img src="../../assets/new-ui/character/raid-fire.png"></li>
      <li><img src="../../assets/new-ui/character/raid-2.png"></li>
      <li><img src="../../assets/new-ui/character/raid-3.png"></li>
      <li><img src="../../assets/new-ui/character/raid-4.png"></li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'CharacterNav',
  components: {}
};
</script>

<style scoped>
.character-nav {
  position: absolute;
  width: 421px;
  top: 70px;
  left: 60px;
  z-index: 3;
}
ul {
  padding: 0;
  margin: 0;
  list-style-type: none;
}
li {
  margin-bottom: 20px;
}
img {
  margin-bottom: 0;
}
</style>
