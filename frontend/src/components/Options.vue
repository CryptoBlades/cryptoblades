<template>
  <b-navbar-nav>
    <b-nav-item-dropdown right>
      <template #button-content>
        <i class="fa fa-cog"></i>
      </template>
      <b-dropdown-item @click="toggleGraphics()">3D Graphics: {{ showGraphics ? 'On' : 'Off' }}</b-dropdown-item>
      <b-dropdown-item @click="toggleRewards()">Reward Bar: {{ hideRewards ? 'Off' : 'On' }}</b-dropdown-item>
      <b-dropdown-item @click="toggleAdvanced()">Advanced UI: {{ hideAdvanced ? 'Off' : 'On' }}</b-dropdown-item>
      <b-dropdown-item @click="toggleHideWalletWarning()">Hide Wallet Warning: {{ hideWalletWarning ? 'On' : 'Off' }}</b-dropdown-item>
    </b-nav-item-dropdown>
  </b-navbar-nav>
</template>

<script>
import Events from '../events';

export default {
  created() {
    this.showGraphics = localStorage.getItem('useGraphics') === 'true';
    this.hideRewards = localStorage.getItem('hideRewards') === 'true';
    this.hideAdvanced = localStorage.getItem('hideAdvanced') === 'true';
    this.hideWalletWarning = localStorage.getItem('hideWalletWarning') === 'true';
  },

  data() {
    return {
      showGraphics: this.showGraphics,
      hideRewards: this.hideRewards,
      hideAdvanced: this.hideAdvanced,
      hideWalletWarning: this.hideWalletWarning,
    };
  },

  methods: {
    toggleGraphics() {
      this.showGraphics = !this.showGraphics;
      if (this.showGraphics) localStorage.setItem('useGraphics', 'true');
      else localStorage.setItem('useGraphics', 'false');

      Events.$emit('setting:useGraphics', { value: this.showGraphics });
    },

    toggleRewards() {
      this.hideRewards = !this.hideRewards;
      if (this.hideRewards) localStorage.setItem('hideRewards', 'true');
      else localStorage.setItem('hideRewards', 'false');

      Events.$emit('setting:hideRewards', { value: this.hideRewards });
    },

    toggleAdvanced() {
      this.hideAdvanced = !this.hideAdvanced;
      if (this.hideAdvanced) localStorage.setItem('hideAdvanced', 'true');
      else localStorage.setItem('hideAdvanced', 'false');

      Events.$emit('setting:hideAdvanced', { value: this.hideAdvanced });
    },

    toggleHideWalletWarning() {
      this.hideWalletWarning = !this.hideWalletWarning;
      if (this.hideWalletWarning) localStorage.setItem('hideWalletWarning', 'true');
      else localStorage.setItem('hideWalletWarning', 'false');

      Events.$emit('setting:hideWalletWarning', { value: this.hideWalletWarning });
    },
  },
};
</script>

<style scoped></style>
