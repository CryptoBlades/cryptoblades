<template>
  <div class="character-bar">
    <character-display />
        <div class="ad-container">
        <Adsense v-if="showAds"
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
import Vue from 'vue';
import CharacterDisplay from './smart/CharacterDisplay.vue';

export default Vue.extend({
  components: {
    CharacterDisplay,
  },
  data() {
    return {
      showAds: false
    };
  },
  methods: {
    checkStorage() {
      this.showAds =  localStorage.getItem('show-ads') === 'true' && !this.isMobile();
    },
    isMobile() {
      return screen.width <= 576;
    },
  },
  async mounted() {
    this.checkStorage();
  },
});
</script>

<style scoped>
.character-bar {
  padding: 0.5em 1.2em;
}
</style>
