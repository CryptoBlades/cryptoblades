<template>
  <b-navbar-nav>

    <router-link :to="{ name: 'plaza' }" exact class="nav-link"
                 v-if="!featureFlagStakeOnly">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="plaza_screen">{{ $t("viewLink.plaza") }}</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'blacksmith' }" exact class="nav-link" v-if="!featureFlagStakeOnly">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="blacksmith_screen">{{ $t("viewLink.blacksmith") }}</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'combat' }" exact class="nav-link" v-if="!featureFlagStakeOnly">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="combat_screen">{{ $t("viewLink.combat") }}</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'raid' }" exact class="nav-link" v-if="!featureFlagStakeOnly && featureFlagRaid">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="raid_screen">{{ $t("viewLink.raid") }}</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'market' }" exact class="nav-link" v-if="!featureFlagStakeOnly && featureFlagMarket">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="market_screen">{{ $t("viewLink.market") }}</span>
      </li>
    </router-link>

    <router-link :to="{ name: 'select-stake-type' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="stake_screen">{{ $t("viewLink.stake") }}</span>
      </li>
    </router-link>

    <router-link v-if="featureFlagPvp" :to="{ name: 'pvp' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="pvp_screen"
              :class="supportsPvP ? '' : 'disabled'">PvP <hint
          v-if="!supportsPvP" class="hint"
          :text="$t('viewLink.functionalityNotSupportedTooltip')"/></span>
      </li>
    </router-link>

    <router-link :to="{ name: 'treasury' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="treasury_screen">Treasury</span>
      </li>
    </router-link>

    <router-link v-if="featureFlagMerchandise" :to="{ name: 'merchandise' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" tagname="merchandise_screen"
              :class="supportsMerchandise ? '' : 'disabled'">{{ $t("viewLink.merchandise") }} <hint
          v-if="!supportsMerchandise" class="hint"
          :text="$t('viewLink.functionalityNotSupportedTooltip')"/></span>
      </li>
    </router-link>

  </b-navbar-nav>
</template>

<script>
import {
  market as featureFlagMarket,
  merchandise as featureFlagMerchandise,
  portal as featureFlagPortal,
  pvp as featureFlagPvp
} from '../feature-flags';
import {mapGetters, mapMutations} from 'vuex';
import Vue from 'vue';
import Hint from '@/components/Hint';

export default Vue.extend({
  inject: ['featureFlagStakeOnly', 'featureFlagRaid'],

  computed: {
    ...mapGetters(['getCurrentChainSupportsMerchandise', 'getCurrentChainSupportsPvP']),
    featureFlagMarket() {
      return featureFlagMarket;
    },
    featureFlagPortal() {
      return featureFlagPortal;
    },
    featureFlagPvp() {
      return featureFlagPvp;
    },
    featureFlagMerchandise() {
      return featureFlagMerchandise;
    },
    supportsMerchandise() {
      return this.getCurrentChainSupportsMerchandise;
    },
    supportsPvP() {
      return this.getCurrentChainSupportsPvP;
    }
  },
  methods: {
    ...mapMutations(['updateCurrentChainSupportsMerchandise', 'updateCurrentChainSupportsPvP']),
  },
  components: {
    Hint,
  },
});
</script>

<style scoped>
a {
  font-weight: bold;
}

.nav-top-links > span {
  color: #BFA765;
  font-size: 1.1em;
  padding: 0px 5px 0px 5px;
}

.disabled {
  cursor: not-allowed;
  color: gray !important;
}
</style>
