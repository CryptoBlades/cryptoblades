<template>
  <b-navbar-nav>

    <router-link :to="{ name: 'plaza' }" exact class="nav-link" v-if="!featureFlagStakeOnly"
     id="gtag-link-others" tagname="plaza_screen">
      <li class="nav-item">
        <span>Plaza</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'blacksmith' }" exact class="nav-link"   v-if="!featureFlagStakeOnly"
     id="gtag-link-others" tagname="blacksmith_screen">
      <li class="nav-item" >
        <span>Blacksmith</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'combat' }" exact class="nav-link"  v-if="!featureFlagStakeOnly"
      id="gtag-link-others" tagname="combat_screen">
      <li class="nav-item" >
        <span>Combat</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'raid' }" exact class="nav-link"  v-if="!featureFlagStakeOnly && featureFlagRaid"
      id="gtag-link-others" tagname="raid_screen">
      <li class="nav-item">
        <span>Raid</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'market' }" exact class="nav-link" v-if="!featureFlagStakeOnly && featureFlagMarket"
     id="gtag-link-others" tagname="market_screen">
      <li class="nav-item">
        <span>Market</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'select-stake-type' }" exact class="nav-link"
      id="gtag-link-others" tagname="stake_screen">
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
