<template>
  <div class="main-nav-div">
    <b-navbar class="main-nav" toggleable="sm" type="dark" variant="dark">
      <b-navbar-brand href="#" class="nav-logo">
        <img src="../assets/logo_Text_Source.png" class="logo d-inline-block align-top" alt="Logo">
      </b-navbar-brand>

      <view-links class="view-links"></view-links>

      <skill-balance-display class="ml-auto d-none d-sm-flex" />

      <claim-rewards  v-if="!canShowRewardsBar" />

      <options class="d-none d-sm-flex"/>

      <!-- Render only on mobile view -->
      <div class="d-flex d-sm-none">
        <skill-balance-display class="skill-display-mobile" />
        <options class="options-display-mobile"/>
      </div>
    </b-navbar>
    <claim-rewards-bar v-if="canShowRewardsBar" />
    <div class="container_row">
      <img src="../assets/divider4.png" class="expander-divider">
      <b-button class="expander-button" @click="toggleCharacterView" v-if="ownCharacters.length > 0">
        <b-icon-arrows-expand class="expand-collapse-icon" v-if="!getIsCharacterViewExpanded" />
        <b-icon-arrows-collapse class="expand-collapse-icon" v-if="getIsCharacterViewExpanded" aria-hidden="true" />
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';

import ViewLinks from './ViewLinks.vue';
import Options from './Options.vue';
import SkillBalanceDisplay from './smart/SkillBalanceDisplay.vue';
import ClaimRewards from './smart/ClaimRewards.vue';
import ClaimRewardsBar from './smart/ClaimRewardsBar.vue';

import Events from '../events';
import { mapGetters, mapMutations } from 'vuex';

export default Vue.extend({
  components: {
    ViewLinks,
    SkillBalanceDisplay,
    ClaimRewards,
    ClaimRewardsBar,
    Options
  },


  data() {
    return {
      canShowRewardsBar: true
    };
  },

  computed: {
    ...mapGetters(['getIsCharacterViewExpanded','ownCharacters'])
  },

  methods: {
    ...mapMutations(['setIsCharacterViewExpanded']),
    checkStorage(): void {
      this.canShowRewardsBar = localStorage.getItem('hideRewards') === 'false';
    },
    toggleCharacterView(): void {
      this.setIsCharacterViewExpanded(!this.getIsCharacterViewExpanded);
      localStorage.setItem('isCharacterViewExpanded', this.getIsCharacterViewExpanded ? 'true' : 'false');
    }
  },

  mounted() {
    this.checkStorage();
    Events.$on('setting:hideRewards', () => this.checkStorage());
  },
});
</script>

<style>

/** Suggest to move this to atomic folder structure like assets/css **/
a {
  text-decoration: none;
  user-select: none;
  color: #b3b0a7 !important;
}

a:hover,
a.router-link-active {
  color: #f2e3bc;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #e1bb34, 0 0 10px #e1bb34;
  text-decoration: none !important;
}

.dropdown-menu {
  background: rgb(20,20,20);
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
  border: none !important;
}

.dropdown-menu li a:hover {
  background: transparent !important;
}
@media (max-width: 1024px) {
 .navbar-expand-sm {
    text-align: center;
    margin: 0 auto;
    display: block;
  }
}



@media (max-width: 576px) {
  .main-nav {
    align-items: normal !important; /** force only for mobile to manually set alignments **/
    flex-direction: column;
  }
  .main-nav > .navbar-brand {
    align-self: center;
  }
  .main-nav > .navbar-nav {
    flex-direction: row;
    justify-content: space-evenly;
  }
  .skill-display-mobile  {
    flex: 5;
  }
  .skill-display-mobile > .balance-container {
    font-size: 0.8em;
  }
  .options-display-mobile {
    flex: 1;
    align-items: flex-end;
  }
  .navbar-expand-sm {
    text-align: center;
    margin: 0 auto;
    display: block;
  }
}
</style>

<style scoped>
.logo {
  max-width: 230px;
  padding-top: 7px;
}

.navbar {
  background: rgb(20,20,20);
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}
.main-nav > .view-links {
  flex : 2.3;
}
.nav-logo {
  flex : 0.5;
}

.expand-collapse-icon {
  position: relative;
  top: -4px;
  left: -10px;
  color: #9e8a57;
}

.expander-button{
  position: relative;
  height: 27px;
  width: 27px;
  top: -12px;
  background: linear-gradient(45deg, rgba(20, 20, 20, 1) 0%, rgba(36, 39, 32, 1) 100%);
  border: 2px solid #312E21 !important;
  border-radius: 0.1em;
  justify-items: center;
}

.container_row{
  display: grid;
  justify-items: center;
}

.expander-divider {
  width: 100%;
  position: relative;
}

.expander-divider, .expander-button{
  grid-column: 1;
  grid-row: 1;
}
</style>


