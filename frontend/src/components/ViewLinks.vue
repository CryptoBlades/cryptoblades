<template>
  <b-navbar-nav>

    <router-link :to="{ name: 'plaza' }" exact class="nav-link"
    v-if="!featureFlagStakeOnly">
      <li class="nav-item">
        <span class="gtag-link-others" tagname="plaza_screen">Plaza</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'blacksmith' }" exact class="nav-link"   v-if="!featureFlagStakeOnly">
      <li class="nav-item" >
        <span class="gtag-link-others" tagname="blacksmith_screen">Blacksmith</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'combat' }" exact class="nav-link"  v-if="!featureFlagStakeOnly">
      <li class="nav-item" >
        <span class="gtag-link-others" tagname="combat_screen">Combat</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'raid' }" exact class="nav-link"  v-if="!featureFlagStakeOnly && featureFlagRaid">
      <li class="nav-item">
        <span class="gtag-link-others" tagname="raid_screen">Raid</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'market' }" exact class="nav-link" v-if="!featureFlagStakeOnly && featureFlagMarket">
      <li class="nav-item">
        <span class="gtag-link-others" tagname="market_screen">Market</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'leaderboard' }" exact class="nav-link" v-if="!featureFlagStakeOnly">
      <li class="nav-item">
        <span class="gtag-link-others" tagname="leaderboard_screen">Leaderboard</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'select-stake-type' }" exact class="nav-link">
      <li class="nav-item">
        <span class="gtag-link-others" tagname="stake_screen">Stake</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'portal' }" exact class="nav-link" v-if="!featureFlagStakeOnly && featureFlagPortal">
      <li class="nav-item">
        <span>Portal</span>
      </li>
    </router-link>

  </b-navbar-nav>
</template>

<script>
import { market as featureFlagMarket, portal as featureFlagPortal } from '../feature-flags';

export default {
  inject: ['featureFlagStakeOnly', 'featureFlagRaid'],

  computed: {
    featureFlagMarket() {
      return featureFlagMarket;
    },
    featureFlagPortal() {
      return featureFlagPortal;
    }
  },
};
</script>

<style scoped>
a {
  font-weight: bold;
}
</style>
