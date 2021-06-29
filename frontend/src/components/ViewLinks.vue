<template>
  <b-navbar-nav>

    <router-link :to="{ name: 'plaza' }" exact class="nav-link gtag-link-others"
    v-if="!featureFlagStakeOnly" tagname="plaza_screen">
      <li class="nav-item">
        <span>Plaza</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'blacksmith' }" exact class="nav-link gtag-link-others"   v-if="!featureFlagStakeOnly"
     tagname="blacksmith_screen">
      <li class="nav-item" >
        <span>Blacksmith</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'combat' }" exact class="nav-link gtag-link-others"  v-if="!featureFlagStakeOnly"
      tagname="combat_screen">
      <li class="nav-item" >
        <span>Combat</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'raid' }" exact class="nav-link gtag-link-others"  v-if="!featureFlagStakeOnly && featureFlagRaid"
      tagname="raid_screen">
      <li class="nav-item">
        <span>Raid</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'market' }" exact class="nav-link gtag-link-others" v-if="!featureFlagStakeOnly && featureFlagMarket"
      tagname="market_screen">
      <li class="nav-item">
        <span>Market</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'select-stake-type' }" exact class="nav-link gtag-link-others"
      tagname="stake_screen">
      <li class="nav-item">
        <span>Stake</span>
      </li>
    </router-link>

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
