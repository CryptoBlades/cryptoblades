<template>
  <div class="main-nav-div">
    <b-navbar class="main-nav bg-dark border-bottom border-gray" toggleable="lg">
      <div class="nav-logo col-xl-2 col-lg-3 col-md-3 col-sm-2 cols-1">
        <router-link :to="{ name: 'dashboard' }" exact class="game-ui-logo">
          <img
            src="../../../../assets/cb-logo.png"
            class="logo d-inline-block align-top"
            alt="Logo"
          />
        </router-link>
      </div>
      <b-collapse id="navbar-toggle-collapse" class="none-mobile" is-nav>
        <view-links class="view-links"></view-links>
      </b-collapse>

      <skill-balance-display class="ml-auto d-none d-sm-flex none-mobile"/>
      <options class="d-none d-sm-flex none-mobile"/>

      <!-- Render only on mobile view -->
        <options class="options-display-mobile d-sm-none"/>
    </b-navbar>
    <skill-balance-display class="skill-display-mobile d-sm-none"/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';

import ViewLinks from '../ViewLinks.vue';
import Options from '../../../options/Options.vue';
import SkillBalanceDisplay from '../../../currency/SkillBalanceDisplay.vue';

import Events from '../../../../utils/events';
import {mapGetters, mapMutations} from 'vuex';

export default Vue.extend({
  components: {
    ViewLinks,
    SkillBalanceDisplay,
    Options,
  },

  data() {
    return {
      canShowRewardsBar: true,
      currentRoute: ''
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

.view-links {
  align-items: center;
  gap: 3rem;
  padding: 0em 2em;
}

.main-nav > .navbar-brand {
  align-self: center;
  padding-bottom: 0;
}

@media (max-width: 1024px) {
  .navbar-expand-sm {
    text-align: center;
    margin: 0 auto;
  }
}

@media (max-width: 576px) {
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
  }

  .skill-display-mobile > .balance-container {
    font-size: 0.8em;
  }

  .balance-container > p {
    font-size: 11px;
  }

  .options-display-mobile {
    display: flex;
    flex: 1;
    align-items: center;
    padding-left: 15px;
    padding-right: 15px;
  }

  .options-display-mobile > img {
    width: 30px;
  }

  .navbar-expand-sm {
    text-align: center;
    margin: 0 auto;
  }

  .deposit-withdraw > span {
    font-size: 12px;
  }

  .deposit-withdraw {
    color: rgba(255, 255, 255, 0.364);
  }

  /* make the the menu inline */
  .main-nav {
    display: flex;
    flex-direction: row;
  }

  .game-ui-logo > img {
    width: 90%;
  }

  .nav-logo {
    width: 100%;
    display: flex;
    justify-content: center;
    flex: 1;
    border: 0;
    margin: 0;
    padding:0;
    transition: 0.5s all;
  }

  .right-details {
    width: 100%;
    flex: 1;
  }

  .skill-tooltip {
    width: fit-content;
  }

  /* hide when in mobile */
  .none-mobile {
    display: none !important;
  }

  .menu-icons {
    width: 100%;
  }

  .row-icons {
    width: 100%;
  }

  .ads {
    order: 2;
  }

  .ads-space {
    width: 100%;
    height: 100%;
    margin-left: 0;
    margin-right: 0;
  }

  .ads {
    order: 2;
  }

  .row-icons {
    height: fit-content;
    margin-bottom: 15px;
  }
}
</style>

<style scoped>
.logo {
  max-width: 85%;
}

.main-nav {
  padding: 0;
  height: 5rem;
}

.x-button {
  width: 100%;
}

.game-ui-logo {
  justify-content: center;
  display: flex;
  align-items: center;
}

.main-nav > .view-links {
  flex: 2.3;
}

.nav-logo {
  height: 100%;
  border-right: 2px solid #404857;
  display: flex;
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
  border: 2px solid #312e21;
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

.game-ui-logo > img {
  width: 90%;
  max-width: 300px;
  margin: auto;
}

@media (max-width: 576px) {
  .main-nav {
    height: 12vh;
  }

  .main-nav > div:nth-child(1){
    flex-grow: 11;
  }

  .main-nav > div.options-display-mobile{
    border-left: 1px solid #707070;
    height: 100%;
  }

  .nav-logo {
    border: 0;
    margin: 0;
  }
}
</style>


