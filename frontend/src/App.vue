<template>
  <div class="app">
    <nav-bar />

    <div class="character-bar">
      <character-display />
    </div>

    <div class="content dark-bg-text">
      <router-view />
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from "vuex";

import NavBar from "./components/NavBar.vue";
import CharacterDisplay from "./components/smart/CharacterDisplay.vue";

export default {
  inject: ["web3"],
  components: {
    NavBar,
    CharacterDisplay,
  },

  computed: {
    ...mapState(["defaultAccount", "currentCharacterId"]),
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
      await this.updateAccounts();
    }, 1000);
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

.app {
  margin: 0;
}

.body {
  display: flex;
  flex-direction: column;
}

.character-bar {
  background-image: url("./assets/title-bar-bg.png");
  padding: 0.5em 1.2em;
}

.content {
  padding: 0 1em;
  background: url('./assets/title-subbar.jpg') repeat-x #030a12;
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
