<template>
  <div class="character-bar">
    <character-display />
  </div>
</template>

<script>
import CharacterDisplay from "./smart/CharacterDisplay.vue";

export default {
  components: {
    CharacterDisplay,
  },
};
</script>

<style scoped>
.character-bar {
  background-image: url("../assets/title-bar-bg.png");
  padding: 0.5em 1.2em;
}
</style>
