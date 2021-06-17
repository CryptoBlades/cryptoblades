<template>
  <b-navbar-nav>
    <b-nav-item-dropdown right>
      <template #button-content>
        <i class="fa fa-cog"></i>
      </template>

      <b-dropdown-item
        @click="toggleGraphics()">3D Graphics: {{ hideGraphics ? 'Off' : 'On' }}</b-dropdown-item>

      <b-dropdown-item
        @click="toggleRewards()">Reward Bar: {{ hideRewards ? 'Off' : 'On' }}</b-dropdown-item>

      <b-dropdown-item
        @click="toggleAdvanced()">Advanced UI: {{ hideAdvanced ? 'Off' : 'On' }}</b-dropdown-item>

    </b-nav-item-dropdown>
  </b-navbar-nav>
</template>

<script>

import Events from '../events';

export default {

  created() {
    this.hideGraphics = !!localStorage.getItem('graphics');
    this.hideRewards = !!localStorage.getItem('rewards');
    this.hideAdvanced = !!localStorage.getItem('advanced');
  },

  data() {
    return {
      hideGraphics: this.hideGraphics,
      hideRewards: this.hideRewards,
      hideAdvanced: this.hideAdvanced
    };
  },

  methods: {
    toggleGraphics() {
      this.hideGraphics = !this.hideGraphics;
      if(this.hideGraphics) localStorage.setItem('graphics', 'off');
      else                  localStorage.removeItem('graphics');

      Events.$emit('setting:graphics', { value: this.hideGraphics });
    },

    toggleRewards() {
      this.hideRewards = !this.hideRewards;
      if(this.hideRewards) localStorage.setItem('rewards', 'off');
      else                 localStorage.removeItem('rewards');

      Events.$emit('setting:rewards', { value: this.hideRewards });
    },

    toggleAdvanced() {
      this.hideAdvanced = !this.hideAdvanced;
      if(this.hideAdvanced) localStorage.setItem('advanced', 'off');
      else                  localStorage.removeItem('advanced');

      Events.$emit('setting:advanced', { value: this.hideAdvanced });
    },
  }
};
</script>

<style scoped>
</style>
