<template>
  <b-navbar-nav>
    <!-- <li class="play-to-earn top-nav-links">
      <P2EButton mainText="Play-to-earn" route="play-to-earn" />
    </li> -->

    <li class="character top-nav-links">
      <router-link v-if="!stakeOnly" :to="{ name: 'plaza' }" exact class="nav-link">
        <div class="icon"><img src="../assets/navbar-icons/plaza-icon.png" class="ui-link-icon" alt="Plaza"></div>
        <div class="link-text">{{ $t("viewLink.character") }}</div>
      </router-link>
    </li>

    <li v-if="!stakeOnly" class="top-nav-links">
      <router-link :to="{ name: 'blacksmith' }" exact class="nav-link">
        <div class="icon"><img src="../assets/navbar-icons/blacksmith-icon.png" class="ui-link-icon" alt="Blacksmith">
        </div>
        <div class="link-text">{{ $t("viewLink.blacksmith") }}</div>
      </router-link>
    </li>

    <li v-if="!stakeOnly" class="top-nav-links">
      <router-link :to="{ name: 'combat' }" exact class="nav-link">
        <div class="icon"><img src="../assets/navbar-icons/combat-icon.png" class="ui-link-icon" alt="Combat"></div>
        <div class="link-text">{{ $t("viewLink.combat") }}</div>
      </router-link>
    </li>

    <li v-if="pvp" class="top-nav-links">
      <router-link v-if="pvp" :to="{ name: 'pvp' }" exact class="nav-link" :class="supportsPvP ? '' : 'disabled-link'">
        <div class="icon"><img src="../assets/navbar-icons/arena-icon.png" class="ui-link-icon" alt="Arena"></div>
        <div class="link-text">{{ $t("viewLink.pvp") }}
          <hint
            v-if="!supportsPvP" class="hint"
            :text="$t('viewLink.functionalityNotSupportedTooltip')"/>
        </div>
      </router-link>
    </li>

    <li v-if="!stakeOnly && raid" class="top-nav-links">
      <router-link :to="{ name: 'raid' }" exact class="nav-link">
        <div class="icon"><img src="../assets/navbar-icons/raid-icon.png" class="ui-link-icon" alt="Raid"></div>
        <div class="link-text">{{ $t("viewLink.raid") }}</div>
      </router-link>
    </li>

    <li v-if="quests" class="top-nav-links">
      <router-link :to="{ name: 'quests'}" exact class="nav-link" :class="supportsQuests ? '' : 'disabled-link'">
        <div class="icon"><img src="../assets/navbar-icons/quests-icon.png" class="ui-link-icon" alt="Quests"></div>
        <div class="link-text">{{ $t("viewLink.quests") }}
          <hint
            v-if="!supportsQuests" class="hint"
            :text="$t('viewLink.functionalityNotSupportedTooltip')"/>
        </div>
      </router-link>
    </li>

    <li v-if="!stakeOnly && market" class="top-nav-links">
      <a href="https://bazaar.market/" class="nav-link" target="_blank">
        <div class="icon"><img src="../assets/navbar-icons/bazaar-icon.png" class="ui-link-icon" alt="Bazaar"></div>
        <div class="link-text">{{ $t("viewLink.bazaar") }}
          <b-icon-box-arrow-up-right scale="0.7"/>
        </div>
      </a>
    </li>

    <li v-if="hasAdminAccess" class="top-nav-links">
      <router-link :to="{ name: 'admin' }" exact class="nav-link">
        <div class="icon"><img src="../assets/navbar-icons/gear-icon.png" class="ui-link-icon" alt="Admin"></div>
        <div class="link-text">{{ $t("viewLink.admin") }}</div>
      </router-link>
    </li>

  </b-navbar-nav>
</template>

<script>
import {market, merchandise, portal, pvp, quests, raid, stakeOnly} from '@/feature-flags';
import {mapGetters, mapState} from 'vuex';
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
    };
  },

  computed: {
    ...mapState(['defaultAccount']),
    ...mapGetters([
      'getCurrentChainSupportsMerchandise',
      'getCurrentChainSupportsPvP',
      'getCurrentChainSupportsQuests',
      'getHasAdminAccess',
      'getHasMinterAccess',
    ]),
    supportsMerchandise() {
      return this.getCurrentChainSupportsMerchandise;
    },
    supportsPvP() {
      return this.getCurrentChainSupportsPvP;
    },
    supportsQuests() {
      return this.getCurrentChainSupportsQuests;
    },
    hasAdminAccess() {
      return this.getHasAdminAccess || this.getHasMinterAccess;
    },
  },

  components: {
    Hint,
  },
});
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Oswald:wght@200;300;400;500;600;700&display=swap');

a {
  font-weight: bold;
}

.nav-top-links {
  list-style-type: none;
}

.nav-top-links > span {
  color: #BFA765;
  font-size: 1.1em;
  padding: 0 5px 0 5px;
}

.ui-link-icon {
  height: 1.5rem;
}

.link-text {
  font-weight: bolder;
  white-space: nowrap;
  font-family: 'Oswald', 'serif';
  font-size: clamp(0.8rem, 1vw, 1rem);
  color: #dfcc9a;
}

.disabled-link > div {
  cursor: not-allowed;
  color: gray;
}

.navbar-nav {
  display: flex;
}

li {
  display: inline-block;
  flex: 1;
}

li:last-child {
  padding-right: 0;
}

.top-nav-links .nav-link {
  padding: 0;
}

li .nav-link {
  text-transform: uppercase;
  font-weight: 500;
  text-align: center;
}

li.active a,
.router-link-exact-active {
  color: #EDCD90;
}

li .nav-link .icon {
  padding-bottom: 0.5rem;
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

@media (max-width: 1366px) {
  .play-to-earn > div {
    text-align: center;
    width: 176px;
  }
}

</style>
