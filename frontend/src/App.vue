<template>
  <div class="app">
    <nav-bar />

    <claim-rewards-bar v-if="canShowRewardsBar" />

    <character-bar v-if="!featureFlagStakeOnly && currentCharacterId !== null" />

    <div class="content dark-bg-text">
      <router-view v-if="canShowApp" />
    </div>

    <div class="fullscreen-warning" v-if="showMetamaskWarning">
      <div>
        You need Metamask installed to use this app.
      </div>
      <a href="https://metamask.io/" target="_blank">Get it here.</a>
    </div>

    <div class="fullscreen-warning" v-if="errorMessage">
      {{ errorMessage }}
    </div>

    <div class="fullscreen-warning" v-if="showNetworkError">
      <div>
        You are currently on the incorrect network.
      </div>
      <div>
        Please switch to <span class="bold">{{ expectedNetworkName }}</span>.
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import _ from 'lodash';

import Events from './events';

import NavBar from './components/NavBar.vue';
import CharacterBar from './components/CharacterBar.vue';
import ClaimRewardsBar from './components/smart/ClaimRewardsBar.vue';

export default {
  inject: ['web3', 'featureFlagStakeOnly', 'expectedNetworkId', 'expectedNetworkName'],
  components: {
    NavBar,
    CharacterBar,
    ClaimRewardsBar
  },

  data: () => ({
    errorMessage: '',
    canShowRewardsBar: true
  }),

  computed: {
    ...mapState(['defaultAccount', 'currentNetworkId', 'currentCharacterId', 'contracts']),

    canShowApp() {
      return !_.isEmpty(this.contracts) && !this.showNetworkError;
    },

    showMetamaskWarning() {
      return !this.web3.currentProvider;
    },

    showNetworkError() {
      return this.expectedNetworkId && this.currentNetworkId !== null && this.currentNetworkId !== this.expectedNetworkId;
    }
  },

  watch: {
    defaultAccount(account) {
      this.web3.eth.defaultAccount = account;
    },

    async currentCharacterId() {
      await this.updateCurrentCharacterStamina();
    },
  },

  methods: {
    ...mapActions({ initializeStore: 'initialize' }),
    ...mapActions(['fetchCharacterStamina', 'pollAccountsAndNetwork']),

    async updateCurrentCharacterStamina() {
      if(this.featureFlagStakeOnly) return;

      if (this.currentCharacterId !== null) {
        await this.fetchCharacterStamina(this.currentCharacterId);
      }
    },

    checkStorage() {
      this.canShowRewardsBar = !localStorage.getItem('rewards');
    }
  },

  mounted() {
    this.checkStorage();

    Events.$on('setting:rewards', () => this.checkStorage());
  },

  async created() {
    try {
      await this.initializeStore();
    } catch(e) {
      this.errorMessage = 'Error: Out of gas or ABI error. Check SKILL and BNB balances.';

      if(e.code === 4001) {
        this.errorMessage = 'Error: MetaMask could not get permissions.';
      }

      console.error(e);
      throw e;
    }

    this.pollCharacterStaminaIntervalId = setInterval(async () => {
      await this.updateCurrentCharacterStamina();
    }, 3000);

    this.doPollAccounts = true;
    const pollAccounts = async () => {
      if(!this.doPollAccounts) return;

      try {
        await this.pollAccountsAndNetwork();
      } catch (e) {
        console.error(e);
      }

      setTimeout(pollAccounts, 200);
    };
    pollAccounts();
  },

  beforeDestroy() {
    this.doPollAccounts = false;
    clearInterval(this.pollCharacterStaminaIntervalId);
  },
};
</script>

<style>
body {
  margin: 0;
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}

.no-margin {
  margin: 0;
}

.bold {
  font-weight: 1000;
}

.main-font {
  font-family: "Roboto", sans-serif;
}

.title-bg-text {
  color: #9e8a57;
}

.dark-bg-text {
  color: #9e8a57;
}

.body {
  max-height: calc(100vh - 56px - 160px);
}

button {
  cursor: pointer;
}

.blank-slate {
  width: calc(100vw - 36px);
  height: calc(100vh - 56px);

  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  font-size: 2rem;
  text-align: center;
}

.error {
  color: red;
}

.fire, .str {
  color: red;
}

.earth, .dex {
  color: green;
}

.water, .int {
  color: cyan;
}

.lightning, .cha {
  color: yellow;
}

.fire-icon, .str-icon {
  color: red;
  content: url("assets/elements/fire.png");
  width: 1em;
  height: 1em;
}

.earth-icon, .dex-icon {
  color: green;
  content: url("assets/elements/earth.png");
  width: 1em;
  height: 1em;
}

.water-icon, .int-icon {
  color: cyan;
  content: url("assets/elements/water.png");
  width: 1em;
  height: 1em;
}

.lightning-icon, .cha-icon {
  color: yellow;
  content: url("assets/elements/lightning.png");
  width: 1em;
  height: 1em;
}

.loading-container {
  position: absolute;
  display: flex;
  justify-content: center;
  align-content: center;
  width: 100%;
  padding-top: 50%;
  font-size: 2rem;
  z-index: 541;
  color: #be9a2c;
}

button.close {
  color: #9e8a57 !important;
}

.btn {
  border: 2px solid #6c5f38 !important;
  border-radius: 0.1em !important;
}

.btn:not(.disabled):hover {
  border: 2px solid #9e8a57 !important;
  background: rgb(61, 61, 64);
  background: linear-gradient(180deg, rgba(51, 51, 54, 1) 0%, rgba(44, 47, 50, 1) 5%, rgba(44, 58, 65, 1) 100%);
}

.btn-primary {
  color: #9e8a57 !important;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.btn-outline-primary {
  color: #9e8a57 !important;
}

.modal-body {
  color: #9e8a57 !important;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.nav-tabs {
  border-bottom: 2px solid #9e8a57 !important;
}

.nav-tabs .nav-link.active {
  border: 2px solid #9e8a57 !important;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.nav-tabs .nav-link:hover, .nav-tabs .nav-link:focus {
  border-color: #9e8a57 #9e8a57 #9e8a57 !important;
}

.outline {
  color: #000;
  text-shadow: -1px 0 #fff, 0 1px #fff, 1px 0 #fff, 0 -1px #fff;
}

div.bg-success {
  background-color: #19682b !important;
}

</style>
<style scoped>
.app {
  margin: 0;
}

.content {
  padding: 0 1em;
  height: calc(100vh - 56px);
  background: rgb(20,20,20);
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}

.fullscreen-warning {
  position: fixed;
  top: 0;
  left: 0;
  background: rgba(0, 0, 0, 0.425);
  height: 100vh;
  width: 100vw;
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  font-size: 3rem;
  color: #fff;
}
</style>
