<template>
  <div class="app">
    <nav-bar />

    <character-bar v-if="!featureFlagStakeOnly && currentCharacterId" />

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

import NavBar from './components/NavBar.vue';
import CharacterBar from './components/CharacterBar.vue';

export default {
  inject: ['web3', 'featureFlagStakeOnly', 'expectedNetworkId', 'expectedNetworkName'],
  components: {
    NavBar,
    CharacterBar,
  },

  data: () => ({
    errorMessage: ''
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

      if (this.currentCharacterId) {
        await this.fetchCharacterStamina(this.currentCharacterId);
      }
    },
  },

  async created() {
    try {
      await this.initializeStore();
    } catch(e) {
      this.errorMessage = 'Error: Out of gas or ABI error.';

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
  background: #030a12;
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
  color: #e1bb34;
}

.dark-bg-text {
  color: #e1bb34;
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

</style>
<style scoped>
.app {
  margin: 0;
}

.content {
  padding: 0 1em;
  background: url("./assets/title-subbar.jpg") 0 -2px repeat-x #030a12;
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
