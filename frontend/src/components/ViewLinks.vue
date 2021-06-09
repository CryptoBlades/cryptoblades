<template>
  <ul class="link-list bold dark-bg-text">
    <li v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'plaza' }" exact
        ><span>Plaza</span></router-link
      >
    </li>
    <li v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'blacksmith' }"
        ><span>Blacksmith</span></router-link
      >
    </li>
    <li v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'combat' }"><span>Combat</span></router-link>
    </li>
    <li v-if="!featureFlagStakeOnly && featureFlagRaid">
      <router-link :to="{ name: 'raid' }"><span>Raid</span></router-link>
    </li>
    <li>
      <router-link :to="{ name: 'select-stake-type' }"><span>Stake</span></router-link>
    </li>
    <li>
      <a @click="toggleGraphics()"><span>3D Graphics: {{ hideGraphics ? 'Off' : 'On' }}</span></a>
    </li>
  </ul>
</template>

<script>
export default {
  inject: ['featureFlagStakeOnly', 'featureFlagRaid'],

  created() {
    this.hideGraphics = !!localStorage.getItem('graphics');
  },

  data() {
    return {
      hideGraphics: this.hideGraphics
    };
  },

  methods: {
    toggleGraphics() {
      this.hideGraphics = !this.hideGraphics;
      if(this.hideGraphics) localStorage.setItem('graphics', 'off');
      else                  localStorage.removeItem('graphics');
    }
  }
};
</script>

<style scoped>
.link-list {
  list-style-type: none;
  padding: 0;
  margin: 0;
  display: flex;
}

.link-list > li {
  margin: 0;
  height: 100%;
  display: flex;
  align-items: stretch;
  font-size: 1.1rem;
  font-weight: bold;
  letter-spacing: 1.5px;
  color: #9e8a57;
}

a {
  padding: 1.2rem;
  text-decoration: none;
  user-select: none;
  color: inherit;
  background: none;
  display: flex;
  justify-content: center;
  flex-direction: column;
}

a:hover,
a.router-link-active {
  color: #f2e3bc;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #e1bb34, 0 0 10px #e1bb34;
}
</style>
