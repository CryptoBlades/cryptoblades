<template>
  <div class="app">
    <nav-bar />

    <character-bar v-if="!featureFlagStakeOnly && currentCharacterId != null" />

    <div class="content dark-bg-text">
      <router-view v-if="canShowApp" />
    </div>

    <div class="fullscreen-warning" v-if="showMetamaskWarning">
      <div>
        You need Metamask installed to use this app. 
      </div>
      <a href="https://metamask.io/" target="_blank">Get it here.</a>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from "vuex";
import _ from "lodash";

import NavBar from "./components/NavBar.vue";
import CharacterBar from "./components/CharacterBar.vue";

export default {
  inject: ["web3", "featureFlagStakeOnly"],
  components: {
    NavBar,
    CharacterBar,
  },

  computed: {
    ...mapState(["defaultAccount", "currentCharacterId", "contracts"]),

    canShowApp() {
      return !_.isEmpty(this.contracts);
    },

    showMetamaskWarning() {
      return !this.web3.currentProvider;
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
    ...mapActions({ initializeStore: "initialize" }),
    ...mapActions(["fetchCharacterStamina", "updateAccounts"]),

    async updateCurrentCharacterStamina() {
      if (this.currentCharacterId != null) {
        await this.fetchCharacterStamina(this.currentCharacterId);
      }
    },
  },

  async created() {
    await this.initializeStore();

    this.pollCharacterStamina = setInterval(async () => {
      await this.updateCurrentCharacterStamina();
    }, 3000);

    this.pollAccounts = setInterval(async () => {
      try {
        await this.updateAccounts();
      } catch (e) {
        console.error(e);
      }
    }, 200);
  },

  beforeDestroy() {
    clearInterval(this.pollAccounts);
    clearInterval(this.pollCharacterStamina);
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
  height: calc(100vh - 56px);
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  font-size: 3rem;
  color: #fff;
}
</style>
