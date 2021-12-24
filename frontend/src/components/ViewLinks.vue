<template>
  <b-navbar-nav>
    <li class="play-to-earn">
      <Button mainText="Play-to-earn" route="play-to-earn"/>
    </li>
    <li class="character">
      <router-link :to="{ name: 'character' }" exact class="nav-link">
        <div class="icon" v-html="$appIcon.NavIcon.Character"></div>
        <div>Character</div>
      </router-link>
    </li>
    <li class="blacksmith">
      <router-link :to="{ name: 'blacksmith' }" exact class="nav-link">
        <div class="icon" v-html="$appIcon.NavIcon.Blacksmith"></div>
        <div>Blacksmith</div>
      </router-link>
    </li>
    <li class="marketplace">
      <router-link :to="{ name: 'marketplace' }" exact class="nav-link">
        <div class="icon" v-html="$appIcon.NavIcon.Marketplace"></div>
        <div>Marketplace</div>
      </router-link>
    </li>
    <li class="leaderboard">
      <router-link :to="{ name: 'leaderboard' }" exact class="nav-link leaderboard">
        <div class="icon" v-html="$appIcon.NavIcon.Leaderboard"></div>
        <div>Leaderboard</div>
      </router-link>
    </li>
  </b-navbar-nav>
</template>

<script>
import { market as featureFlagMarket, portal as featureFlagPortal } from '../feature-flags';
import Button from '@/components/Button';
export default {
  components : {
    Button
  },
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
.navbar-nav {
  display: flex;
}
li {
  display: inline-block;
  padding-right: 38px;
}
li:last-child {
  padding-right: 0;
}
li .nav-link {
  font-family: 'Oswald';
  font-size: 18px;
  text-transform: uppercase;
  font-weight: 500;
  text-align: center;
}
li .nav-link .icon {
  margin-bottom: 5px;
}
.play-to-earn {
  display: flex;
  align-items: center;
}
.play-to-earn a {
  border: 1px solid #EDCD90;
  display: block;
  padding: 20px;
}
</style>
