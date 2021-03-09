<template>
  <div class="app">
    <div class="top-bar">
      <h1 class="app-title">{{ appName }}</h1>
      <view-links></view-links>
    </div>

    <div class="content">
      <router-view :character="character" :weapons="weapons" :stamina="stamina" />
    </div>
  </div>
</template>

<script>
import ViewLinks from "./components/ViewLinks.vue";

export default {
  inject: ["Kryptoknights"],
  components: {
    ViewLinks,
  },

  data() {
    return {
      appName: "Unknown",
      character: {
        name: "Bimmy Bozo",
        level: 12,
        experience: 10,
      },
      stamina: {
        current: 85,
        max: 120
      },
      weapons: ["one", "two", "three", "four", "five", "six", "seven", "steve"],
    };
  },

  created() {
    this.Kryptoknights.methods
      .getName()
      .call()
      .then((res) => {
        this.appName = res;
      }, console.error);
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

.top-bar {
  background: rgb(0, 217, 224);
  display: flex;
  align-items: baseline;
  padding: 1em;
}

.app-title {
  margin: 0;
  margin-right: 1em;
}

.content {
  padding: 0 1em;
}
</style>
