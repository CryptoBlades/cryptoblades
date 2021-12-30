<template>
  <div class="character-bar">
    <character-display/>
    <div v-if="showAds && !isMobile()" class="ad-container">
      <script2 async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-6717992096530538"
               crossorigin="anonymous"></script2>
      <ins class="adsbygoogle" style="display:inline-block;width:970px;height:90px"
           data-ad-client="ca-pub-6717992096530538" data-ad-slot="5115599573"/>
      <script2> (adsbygoogle = window.adsbygoogle || []).push({});</script2>
      <ins class="61c208e596bc5000134ec909" style="display:inline-block;width:970px;height:90px;"/>
      <script2>!function (e, n, c, t, o, r) { !function e(n, c, t, o, r, m, s, a) { s = c.getElementsByTagName(t)[0], (a
        = c.createElement(t)).async = !0, a.src = "https://" + r[m] + "/js/" + o + ".js", a.onerror = function () {
        a.remove(), (m += 1) >= r.length || e(n, c, t, o, r, m) }, s.parentNode.insertBefore(a, s) }(window, document,
        "script", "61c208e596bc5000134ec909", ["cdn.bmcdn2.com"], 0) }();
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
      this.showAds = localStorage.getItem('show-ads') === 'true';
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

.ad-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
</style>
