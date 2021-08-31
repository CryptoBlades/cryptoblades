<template>
  <div class="character-bar">
    <character-display />

    <ins class="adsbygoogle"
        style="display:block"
        data-ad-client="ca-pub-6717992096530538"
        data-ad-slot="5115599573"
        data-ad-format="auto"
        data-full-width-responsive="true"></ins>

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
