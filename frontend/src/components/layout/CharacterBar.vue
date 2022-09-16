<template>
  <b-col :class="renderPageDisplay()" class="animates">
    <div class="character-bar">
      <character-display :toggled="isToggled" :currentPath="currentPath" :key="componentKey"/>
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
    </div>
  </b-col>
</template>

<script lang="ts">
import Vue from 'vue';
import CharacterDisplay from '../smart/CharacterDisplay.vue';
import '@/mixins/general';


export default Vue.extend({
  props: ['isToggled', 'sidebarType'],
  components: {
    CharacterDisplay,
  },
  data() {
    return {
      showAds: false,
      componentKey: 0,
      currentPath: ''
    };
  },
  methods: {
    checkStorage() {
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
    },
    renderPageDisplay(){
      let toDisplay;

      if(this.isToggled){
        toDisplay = 'sideBorder';
      }else{
        toDisplay = 'col-xl-2 col-lg-3 col-md-3 col-sm-2 cols-1';
      }
      return toDisplay;
    },
  },
  computed:{
    isTablet() {
      if (screen.width <= 900) {
        return true;
      } else {
        return false;
      }
    },
  },
  async mounted() {
    this.checkStorage();
    this.currentPath = (this as any).$route.path;
  },
  watch:{
    $route (to){
      this.currentPath = to.path;
    },
  }
});
</script>

<style>
.animates{
  padding-top: 30px;
  transition: 1s all ease-in-out;
  border-right: 1px solid rgba(255, 255, 255, 0.234);
}

.content > .row > .sideBorder{
  max-width: 100px;
  min-width: 100px;
}

.sideBorder{
  overflow: visible;
  border-right: 1px solid rgba(255, 255, 255, 0.234);
  transition: all 0.7s ease-in-out;
}

.sideBar{
  max-width: 100px;
  min-width: 100px;
  border-right: 1px solid rgba(255, 255, 255, 0.234);
  transition: all 0.7s ease-in-out;
}

.set-active{
  max-width: 350px;
  min-width: 350px;
  border-right: 1px solid rgba(255, 255, 255, 0.234);
  transition: all 0.7s ease-in-out;
}

.character-bar {
  padding: 0.5em 0.8em;
}

@media (max-width: 575.98px) {
  .show-reforged {
    width: 100%;
    justify-content: center;
    display: block;
  }

  .animates{
    padding-top: 30px;
  }


  .sideBorder{
    padding-top: 30px;
  }
}

@media all and (max-width: 900px )and (min-width: 601px) {
  .sideBar{
    max-width: 110px;
    min-width: 110px;
    border-right: 1px solid rgba(255, 255, 255, 0.234);
    transition: all 0.7s ease-in-out;
  }

  .change-weapon[data-v-8bdfa084] {
    position: absolute;
    right: 0;
    top: 0;
    height: 100vh;
    width: 60%;
    z-index: 5;
    background-color: rgb(27, 29, 24);
    overflow-x: auto;
  }
}

.sideBar{
  position: inline;
  z-index: 99;
  background-color: rgba(20, 20, 20, 1);
  width: fit-content;
}

.ad-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

</style>
