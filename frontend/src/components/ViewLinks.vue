<template>
  <b-navbar-nav>
    <b-nav-item v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'plaza' }" exact><span>Plaza</span></router-link>
    </b-nav-item>

    <b-nav-item v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'blacksmith' }" exact><span>Blacksmith</span></router-link>
    </b-nav-item>

    <b-nav-item v-if="!featureFlagStakeOnly">
      <router-link :to="{ name: 'combat' }" exact><span>Combat</span></router-link>
    </b-nav-item>

    <b-nav-item v-if="!featureFlagStakeOnly && featureFlagRaid">
      <router-link :to="{ name: 'raid' }" exact><span>Raid</span></router-link>
    </b-nav-item>

    <b-nav-item v-if="!featureFlagStakeOnly && featureFlagMarket">
      <router-link :to="{ name: 'market' }" exact><span>Market</span></router-link>
    </b-nav-item>

    <b-nav-item>
      <router-link :to="{ name: 'select-stake-type' }" exact><span>Stake</span></router-link>
    </b-nav-item>
  </b-navbar-nav>
</template>

<script>
import { market as featureFlagMarket } from '../feature-flags';

export default {
  inject: ['featureFlagStakeOnly', 'featureFlagRaid'],

  computed: {
    featureFlagMarket() {
      return featureFlagMarket;
    }
  },
};
</script>

<style scoped>
a {
  font-weight: bold;
}
</style>
