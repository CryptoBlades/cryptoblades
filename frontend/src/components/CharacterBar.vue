<template>
  <b-col :class="renderPageDisplay()" class="animates">
    <div class="character-bar">
      <character-display :toggled="isToggled" :currentPath="currentPath" :key="componentKey"/>
      <div class="claim-reward" v-if="!isToggled">
        <p id="popover-1-claim">{{$t('ClaimRewardsBar.cliamExp')}}</p>
        <p @click="gotoGarison">{{$t('ClaimRewardsBar.visitGarison')}}</p>
        <b-popover
          target="popover-1-claim"
          :placement="placement"
          triggers="hover focus click"
          custom-class="exp-popover"
        >
          <div>
            <claim-rewards-bar isFor="claimExp"/>
          </div>
        </b-popover>
      </div>
      <div v-if="isToggled">
        <hr class="boundary">
        <p class="btn-diamond-border" id="popover-1-claim">
          <span class="exp-icon"></span>
        </p>
        <p class="btn-diamond-border">
          <span class="garisson-icon"></span>
        </p>
        <b-popover
          target="popover-1-claim"
          :placement="placement"
          triggers="hover focus click"
          custom-class="exp-popover"
        >
          <div>
            <claim-rewards-bar isFor="claimExp"/>
          </div>
        </b-popover>
      </div>
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
import CharacterDisplay from './smart/CharacterDisplay.vue';
import '@/mixins/general';
import ClaimRewardsBar from './smart/ClaimRewardsBar.vue';


export default Vue.extend({
  props: ['isToggled', 'sidebarType'],
  components: {
    CharacterDisplay,
    ClaimRewardsBar
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
    gotoGarison(){
      (this as any).$router.push({ name: 'plaza'});
    }
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

.sideBorder{
  overflow: visible;
  max-width: 100px;
  min-width: 100px;
  border-right: 1px solid rgba(255, 255, 255, 0.234);
  transition: all 0.7s ease-in-out;
}

.claim-reward{
  display: flex;
  flex-direction: column;
}

.exp-popover{
  background-color: #000;
}

.popover.bottom .arrow {visibility:hidden;}

.claim-reward > p {
  font-family: Roboto;
  color: #EDCD90;
  width: 100%;
  display: flex;
  font-size: 14px;
  justify-content: center;
  padding: 10px;
  border-radius: 5px;
  border: 1px solid #EDCD90;
  cursor: pointer;
}

.boundary{
  border: 1px solid rgba(255, 255, 255, 0.411);
  margin-bottom: 50px;
}

.exp-icon{
  content: url('../assets/exp.png');
  height: 60px;
  widows: 60px;
}

.garisson-icon{
  content: url('../assets/garisson.png');
  height: 60px;
  widows: 60px;
}

.claim-reward > p:hover {
  color: #ffffff;
  border: 1px solid #ffffff;
  transition: 0.3s all ease-in-out;
}

.btn-diamond-border {
  border: 1px solid #dabf75;
  display: flex;
  align-items: center;
  justify-content: center;
  transform: rotate(45deg);
  height: 50px;
  width: 50px;
  margin-bottom: 50px;
  cursor: pointer;
  transition: 0.3s all ease-in-out;
  transition-delay: 1s;
}

.btn-diamond-border > span{
  padding: 7px;
  display: flex;
  align-items: center;
  justify-content: center;
  transform: rotate(-45deg);
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
  height: 88vh;
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
    z-index: 9999;
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
