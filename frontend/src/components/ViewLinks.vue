<template>
  <b-navbar-nav>
    <!-- <li class="play-to-earn top-nav-links">
      <P2EButton mainText="Play-to-earn" route="play-to-earn" />
    </li> -->

    <li class="character top-nav-links" >
      <router-link v-if="!stakeOnly" :to="{ name: 'plaza' }" exact class="nav-link">
        <div class="icon"> <img src="../assets/new-ui/new-plaza-icon.png" class="new-ui-links-icon"></div>
        <div class="link-text">Character</div>
      </router-link>
    </li>

   <li v-if="!stakeOnly" class="top-nav-links" >
      <router-link :to="{ name: 'blacksmith' }" exact class="nav-link">
        <div class="icon"><img src="../assets/new-ui/new-blacksmith-icon.png" class="new-ui-links-icon"></div>
        <div class="link-text">Blacksmith</div>
      </router-link>
    </li>

    <li v-if="!stakeOnly" class="top-nav-links" >
      <router-link :to="{ name: 'combat' }" exact class="nav-link">
        <div class="icon"><img src="../assets/new-ui/new-combat-icon.png" class="new-ui-links-icon"></div>
        <div class="link-text">Combat</div>
      </router-link>
    </li>

    <li v-if="pvp" class="top-nav-links">
      <router-link :to="{ name: 'pvp' }" exact class="nav-link">
        <div class="icon"><img src="../assets/new-ui/new-arena-icon.png" class="new-ui-links-icon"></div>
        <div class="link-text">Arena </div>
      </router-link>
    </li>

   <li v-if="!stakeOnly && raid" class="top-nav-links">
      <router-link :to="{ name: 'raid' }" exact class="nav-link">
        <div class="icon"><img src="../assets/new-ui/new-raid-icon.png" class="new-ui-links-icon"></div>
        <div  class="link-text">Raid </div>
      </router-link>
    </li>

    <li  v-if="!stakeOnly && market" class="top-nav-links">
      <a href="https://bazaar.market/"  class="nav-link" target="_blank">
        <div class="icon"> <img src="../assets/new-ui/new-bazaar-icon.png" class="new-ui-links-icon"> </div>
        <div  class="link-text">Bazaar</div>
      </a>
    </li>


  </b-navbar-nav>
</template>

<script>
import {market, merchandise, portal, pvp, quests, raid, stakeOnly} from '@/feature-flags';
import {mapActions, mapGetters, mapState} from 'vuex';
import Vue from 'vue';
// import Hint from '@/components/Hint';
// import P2EButton from '@/components/P2EButton';

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

  components: {
    // Hint,
    // P2EButton
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

.new-ui-links-icon {
  height:25px;
}

.link-text {
  font-weight: bolder;
}

.disabled {
  cursor: not-allowed;
  color: gray !important;
}

.navbar-nav {
  display: flex;
}
li {
  display: inline-block;
  width: 110px;
}

li:last-child {
  padding-right: 0;
}

li .nav-link {
  font-size: 18px;
  text-transform: uppercase;
  font-weight: 500;
  text-align: center;
}

li.active a,
.router-link-exact-active {
  color: #EDCD90;
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

@media (max-width: 1366px) {
  .top-nav-links > a {
    font-size: 0.7rem;
  }
  .play-to-earn > div {
    text-align: center;
    width: 176px;
  }
}
</style>
