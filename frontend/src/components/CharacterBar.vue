<template>
  <div class="character-bar">
    <character-display />
    <img src="../assets/infoDivider.png" class="info-divider">
  </div>
</template>

<script lang="ts">
import CharacterDisplay from './smart/CharacterDisplay.vue';

export default {
  components: {
    CharacterDisplay,
  },
};
</script>

<style scoped>
.character-bar {
  padding: 0.5em 1.2em;
}
</style>
