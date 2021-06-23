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
      <div class="starter-panel">
          <img class="mini-icon-starter" src="./assets/placeholder/sword-placeholder-6.png" alt="" srcset="" />
          <span class="starter-panel-heading">{{errorMessage}}
        </span>
         <img class="mini-icon-starter" src="./assets/placeholder/sword-placeholder-6.png" alt="" srcset="" />
        <div class="seperator"></div>
        <div class="instructions-list">
          <p>
            Get Started in less than 10 minutes!
            To Recruit your first character you need 5 Skill and .001 BNB.
            You also need .0015 BNB to do your first battles. But don't worry.
            You earn the battle fees back in SKILL rewards immediately!
          </p>
        <ul class="unstyled-list">
          <li>1. How Buy BNB w/ fiat <a href="https://youtu.be/6-sUDUE2RPA" target="_blank" rel="noopener noreferrer">Watch Video</a> </li>
          <li>2. Once you have BNB, go to ApeSwap to obtain SKILL tokens:<br/> <a href="https://dex.apeswap.finance/#/swap?outputCurrency=0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab">https://dex.apeswap.finance/#/swap?outputCurrency=0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab</a></li>
          <li>3. Read the alert and Select “I understand” and “Continue”</li>
          <li>4. Then follow the following tutorial to swap BNB for SKILL! <a href="https://youtu.be/_zitrvJ7Hl4" target="_blank" rel="noopener noreferrer">Watch Video</a></li>
          <li>5. That's it! Now you can create your first Character (<a href="https://youtu.be/ZcNq0jCa28c" target="_blank" rel="noopener noreferrer">Watch Getting Started</a>)</li>
        </ul>

        <p>If you have any questions at all, talk to us on our Discord at: <a href="https://discord.gg/c5afzyQ3Q9" target="_blank" rel="noopener noreferrer">https://discord.gg/c5afzyQ3Q9</a></p>
        </div>
      </div>
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
import { mapState, mapActions, mapGetters } from 'vuex';
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
    ...mapState(['defaultAccount', 'currentNetworkId', 'currentCharacterId']),
    ...mapGetters(['contracts']),

    canShowApp() {
      return this.contracts !== null && !_.isEmpty(this.contracts) && !this.showNetworkError;
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
    ...mapActions([
      'fetchCharacterStamina',
      'pollAccountsAndNetwork',
      'fetchWeaponTransferCooldownForOwnWeapons',
      'fetchCharacterTransferCooldownForOwnCharacters'
    ]),

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
      this.errorMessage = 'Welcome to CryptoBlades. Here\'s how you can get started.';
      if(e.code === 4001) {
        this.errorMessage = 'Error: MetaMask could not get permissions.';
      }

      console.error(e);
      throw e;
    }

    this.pollCharacterStaminaIntervalId = setInterval(async () => {
      await this.updateCurrentCharacterStamina();
    }, 3000);

    this.weaponTransferCooldownPollIntervalId = setInterval(async () => {
      await Promise.all([
        this.fetchCharacterTransferCooldownForOwnCharacters(),
        this.fetchWeaponTransferCooldownForOwnWeapons()
      ]);
    }, 10 * 1000);

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
    clearInterval(this.weaponTransferCooldownPollIntervalId);
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

.starter-panel {
  width: 25em;
  height: 10.5em;
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 2px 4px #ffffff38;
  border :1px solid #9e8a57;
  border-radius: 5px;
  padding: 0.5em;
  margin: auto;
  text-align: center;
}

.starter-panel-heading {
  margin-left : 15px;
  font-size : 45px;
}

.starter-msg {
  font-size: 0.85em;
}
.instructions-list {
  text-align: start;
  padding : 15px;
  font-size : 0.5em;
}

.unstyled-list {
  list-style-type: none;
}
.seperator {
  border: 1px solid #9e8a57;
  border-radius: 3px;
  width : 100%;
}

.mini-icon-starter {
  height: 1.2em;
  width: 1.2em;
  margin : 5px;
}
</style>
