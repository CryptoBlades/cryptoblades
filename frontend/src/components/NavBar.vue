<template>
  <div class="main-nav-div">
    <b-navbar class="main-nav" toggleable="sm">
      <b-navbar-brand href="#" class="nav-logo">
        <router-link :to="{ name: 'plaza' }" exact class="new-game-ui-logo">
          <img
            src="../assets/cb-logo.png"
            class="logo d-inline-block align-top"
            alt="Logo"
          />
        </router-link>
      </b-navbar-brand>

      <b-navbar-toggle target="navbar-toggle-collapse" class="none-mobile">
        <template #default="{ expanded }">
          <b-icon v-if="expanded" icon="chevron-bar-up"></b-icon>
          <b-icon v-else icon="chevron-bar-down"></b-icon>
        </template>
      </b-navbar-toggle>

      <b-collapse id="navbar-toggle-collapse" class="none-mobile" is-nav>
        <view-links class="view-links"></view-links>
      </b-collapse>

      <skill-balance-display class="ml-auto d-none d-sm-flex none-mobile" />
      <options class="d-none d-sm-flex none-mobile" />

      <!-- Render only on mobile view -->
      <div class="d-flex d-sm-none right-details">
        <skill-balance-display class="skill-display-mobile" />
        <options class="options-display-mobile" />
      </div>
    </b-navbar>
    <claim-rewards-bar v-if="canShowRewardsBar" />
    <div class="container_row">
      <img src="../assets/divider4.png" class="expander-divider" />
      <b-button
        class="expander-button"
        @click="toggleCharacterView"
        v-if="ownCharacters.length > 0"
      >
        <b-icon-arrows-expand
          class="expand-collapse-icon"
          v-if="!getIsCharacterViewExpanded"
        />
        <b-icon-arrows-collapse
          class="expand-collapse-icon"
          v-if="getIsCharacterViewExpanded"
          aria-hidden="true"
        />
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';

import ViewLinks from './ViewLinks.vue';
import Options from './Options.vue';
import SkillBalanceDisplay from './smart/SkillBalanceDisplay.vue';
import ClaimRewardsBar from './smart/ClaimRewardsBar.vue';

import Events from '../events';
import { mapGetters, mapMutations } from 'vuex';

export default Vue.extend({
  components: {
    ViewLinks,
    SkillBalanceDisplay,
    ClaimRewardsBar,
    Options,
  },

  data() {
    return {
      canShowRewardsBar: true,
    };
  },

  computed: {
    ...mapGetters(['getIsCharacterViewExpanded', 'ownCharacters']),
  },

  methods: {
    ...mapMutations(['setIsCharacterViewExpanded']),
    checkStorage(): void {
      this.canShowRewardsBar = localStorage.getItem('hideRewards') === 'false';
    },
    toggleCharacterView(): void {
      this.setIsCharacterViewExpanded(!this.getIsCharacterViewExpanded);
      localStorage.setItem(
        'isCharacterViewExpanded',
        this.getIsCharacterViewExpanded ? 'true' : 'false'
      );
    },
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

.main-nav > .navbar-brand {
  align-self: center;
  padding-bottom: 0px !important;
}
.dropdown-menu {
  background: rgb(20, 20, 20);
  background: linear-gradient(
    45deg,
    rgba(20, 20, 20, 1) 0%,
    rgba(36, 39, 32, 1) 100%
  );
  border: none !important;
}

.dropdown-menu li a:hover {
  background: transparent !important;
}
@media (max-width: 1024px) {
  .navbar-expand-sm {
    text-align: center;
    margin: 0 auto;
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
  .skill-display-mobile {
    flex: 5;
    display: flex;
    align-items: center;
    height: 90px !important;
  }
  .skill-display-mobile > .balance-container {
    font-size: 0.8em;
  }

  .balance-container > p{
    font-size: 11px;
  }

  .options-display-mobile {
    display: flex;
    flex: 1;
    align-items: center;
    padding-left: 15px !important;
    padding-right: 15px !important;
  }

  .options-display-mobile > img{
    width: 30px!important ;
  }

  .navbar-expand-sm {
    text-align: center;
    margin: 0 auto;
  }

  .deposit-withdraw > span{
    font-size: 12px;
  }

  .deposit-withdraw{
    color: rgba(255, 255, 255, 0.364);
  }

  /* make the the menu inline */
  .main-nav {
    display: flex;
    flex-direction: row;
  }

  .new-game-ui-logo > img {
    width: 90%;
  }
  .nav-logo {
    /* margin-right: 0 !important; */
    width: 100%;
    display: block;
    flex: 1  !important;
  }
  .right-details {
    width: 100%;
    flex: 1 !important;
  }

  .skill-tooltip{
    width: fit-content  !important;
  }

  /* hide when in mobile */
  .none-mobile {
    display: none !important;
  }

  .menu-icons {
    width: 100% !important;
  }

  .row-icons {
    width: 100%;
  }

  .ads {
    order: 2 !important;
  }

  .ads-space {
    width: 100% !important;
    height: 100% !important;
    margin-left: 0px !important;
    margin-right: 0px !important;
  }

  .ads {
    order: 2;
  }

  .menu-icon > img {
    height: 20px;
    width: 20px;
  }

  .menu-icon {
    margin-left: 10px !important;
    width: 70px !important;
    height: 70px !important;
    font-size: 13px;
    padding: 0px !important;
    display: flex;
    flex-direction: column;
    justify-content: center !important;
    align-items: center !important;
  }

  .menu-icon > p {
    margin-bottom: 0px !important;
  }

  .row-icons {
    height: fit-content !important;
    margin-bottom: 15px;
  }
}
</style>

<style scoped>
.logo {
  max-width: 280px;
}

.main-nav {
  padding: 0px;
}

.x-button {
  width: 100%;
}

@media (min-width: 1024px) {
  .new-game-ui-logo {
    height: 100px;
    width: 400px;
    justify-content: center;
    display: flex;
    align-items: center;
    border-right: 2px solid #404857;
  }
}

.navbar {
  background: linear-gradient(45deg, #141414, #242720);
  border-bottom: 2px solid #404857;
}
.main-nav > .view-links {
  flex: 2.3;
}
.nav-logo {
  flex: 0.5;
}

.expand-collapse-icon {
  position: relative;
  top: -4px;
  left: -10px;
  color: #9e8a57;
}

.expander-button {
  position: relative;
  height: 27px;
  width: 27px;
  top: -12px;
  background: linear-gradient(
    45deg,
    rgba(20, 20, 20, 1) 0%,
    rgba(36, 39, 32, 1) 100%
  );
  border: 2px solid #312e21 !important;
  border-radius: 0.1em;
  justify-items: center;
}

.container_row {
  display: grid;
  justify-items: center;
}

.expander-divider {
  width: 100%;
  position: relative;
}

.expander-divider,
.expander-button {
  grid-column: 1;
  grid-row: 1;
}
</style>


