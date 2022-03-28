<template>
  <div class="character-bar">
    <character-display/>
    <div v-if="showAds && !isMobile()" class="ad-container">
      <script2 async src="https://coinzillatag.com/lib/display.js"></script2>
        <div class="coinzilla" data-zone="C-541621de2f7bb717603"></div>
          <script2>
                window.coinzilla_display = window.coinzilla_display || [];
                var c_display_preferences = {};
                c_display_preferences.zone = "541621de2f7bb717603";
                c_display_preferences.width = "728";
                c_display_preferences.height = "90";
                coinzilla_display.push(c_display_preferences);
          </script2>
    </div>
    <img src="../assets/infoDivider.png" class="info-divider" alt=""/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import CharacterDisplay from './smart/CharacterDisplay.vue';
import '@/mixins/general';

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
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
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

@media all and (max-width: 600px) {
  .character-bar {
    padding: 0.5em 0.6em;
  }
}

.ad-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}


</style>
