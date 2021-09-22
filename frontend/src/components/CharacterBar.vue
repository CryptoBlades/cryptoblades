<template>
  <div class="character-bar">
    <character-display />
        <div class="ad-container">
        <Adsense
          data-ad-client="ca-pub-6717992096530538"
          data-ad-slot="5115599573"
          data-ad-format="auto"
          data-full-width-responsive="yes"
          >
        </Adsense>
      </div>

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
