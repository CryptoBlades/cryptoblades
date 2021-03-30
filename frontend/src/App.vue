<template>
  <div class="app">
    <nav-bar />

    <div class="content">
      <router-view />
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from "vuex";

import NavBar from "./components/NavBar.vue";

export default {
  inject: ["web3"],
  components: {
    NavBar,
  },

  computed: {
    ...mapState(["defaultAccount"]),
  },

  watch: {
    defaultAccount(account) {
      this.web3.eth.defaultAccount = account;
    },
  },

  methods: {
    ...mapActions({ initializeStore: "initialize" }),
  },

  async created() {
    await this.initializeStore();
  },
};
</script>

<style>
body {
  margin: 0;
}

.app {
  margin: 0;
}

.content {
  padding: 0 1em;
}

.bold {
  font-weight: 1000;
}

.main-font {
  font-family: "Roboto", sans-serif;
}

.dark-bg-text {
  opacity: 90%;
  color: white;
}
</style>
