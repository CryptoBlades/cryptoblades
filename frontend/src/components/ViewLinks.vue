<template>
  <b-navbar-nav>

    <router-link v-if="!stakeOnly" :to="{ name: 'plaza' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others">{{ $t("viewLink.plaza") }}</span>
      </li>
    </router-link>

    <router-link v-if="!stakeOnly" :to="{ name: 'blacksmith' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others">{{ $t("viewLink.blacksmith") }}</span>
      </li>
    </router-link>

    <router-link v-if="!stakeOnly" :to="{ name: 'combat' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others">{{ $t("viewLink.combat") }}</span>
      </li>
    </router-link>

    <router-link v-if="!stakeOnly && raid" :to="{ name: 'raid' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others">{{ $t("viewLink.raid") }}</span>
      </li>
    </router-link>

    <a v-if="!stakeOnly && market" href="https://bazaar.market/" class="nav-link" target="_blank">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others">{{ $t("viewLink.bazaar") }} <b-icon-box-arrow-up-right scale="0.7"/></span>
      </li>
    </a>

    <router-link :to="{ name: 'select-stake-type' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others">{{ $t("viewLink.stake") }}</span>
      </li>
    </router-link>

    <router-link v-if="pvp" :to="{ name: 'pvp' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" :class="supportsPvP ? '' : 'disabled'">{{ $t("viewLink.pvp") }} <hint
          v-if="!supportsPvP" class="hint"
          :text="$t('viewLink.functionalityNotSupportedTooltip')"/></span>
      </li>
    </router-link>

    <router-link v-if="quests" :to="{ name: 'quests' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" :class="supportsQuests ? '' : 'disabled'">{{ $t("viewLink.quests") }} <hint
          v-if="!supportsQuests" class="hint"
          :text="$t('viewLink.functionalityNotSupportedTooltip')"/></span>
      </li>
    </router-link>

    <router-link :to="{ name: 'treasury' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others">{{ $t("viewLink.treasury") }}</span>
      </li>
    </router-link>

    <router-link v-if="merchandise" :to="{ name: 'merchandise' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others" :class="supportsMerchandise ? '' : 'disabled'">{{ $t("viewLink.merchandise") }} <hint
          v-if="!supportsMerchandise" class="hint"
          :text="$t('viewLink.functionalityNotSupportedTooltip')"/></span>
      </li>
    </router-link>

    <router-link v-if="hasAdminAccess" :to="{ name: 'admin' }" exact class="nav-link">
      <li class="nav-item nav-top-links">
        <span class="gtag-link-others">{{ $t("viewLink.admin") }}</span>
      </li>
    </router-link>

  </b-navbar-nav>
</template>

<script>
import {market, merchandise, portal, pvp, quests, raid, stakeOnly} from '@/feature-flags';
import {mapActions, mapGetters, mapState} from 'vuex';
import Vue from 'vue';
import Hint from '@/components/Hint';

export default Vue.extend({
  data() {
    return {
      stakeOnly,
      raid,
      market,
      portal,
      pvp,
      quests,
      merchandise,
      hasAdminAccess: false,
    };
  },

  computed: {
    ...mapState(['defaultAccount']),
    ...mapGetters(['getCurrentChainSupportsMerchandise', 'getCurrentChainSupportsPvP', 'getCurrentChainSupportsQuests']),
    supportsMerchandise() {
      return this.getCurrentChainSupportsMerchandise;
    },
    supportsPvP() {
      return this.getCurrentChainSupportsPvP;
    },
    supportsQuests() {
      return this.getCurrentChainSupportsQuests;
    },
  },

  methods: {
    ...mapActions(['userHasAnyAdminAccess', 'userHasAnyMinterAccess']),

    async fetchData() {
      this.hasAdminAccess = await this.userHasAnyAdminAccess() || await this.userHasAnyMinterAccess();
    },
  },

  mounted() {
    this.fetchData();
  },

  components: {
    Hint,
  },

  watch: {
    async defaultAccount(newVal) {
      if (newVal) {
        await this.fetchData();
      }
    },
  }
});
</script>

<style scoped>
a {
  font-weight: bold;
}

.nav-top-links > span {
  color: #BFA765;
  font-size: 1.1em;
  padding: 0 5px 0 5px;
}

.disabled {
  cursor: not-allowed;
  color: gray !important;
}
</style>
