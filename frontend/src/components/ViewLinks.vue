<template>
  <b-navbar-nav>
    <li class="top-nav-links">
      <router-link :to="{ name: 'play-to-earn' }" exact class="nav-link">
        <div class="link-text play-to-earn-btn">{{ $t("PlayToEarn.playToEarn") }}</div>
      </router-link>
    </li>
    <li class="top-nav-links ml-4">
      <router-link :to="{ name: 'plaza' }" exact class="nav-link">
        <div class="icon"><img src="../assets/navbar-icons/plaza-icon.png" class="ui-link-icon" alt="Plaza"></div>
        <div class="link-text">{{ $t("viewLink.character") }}</div>
      </router-link>
    </li>

    <li class="top-nav-links">
      <router-link :to="{ name: 'blacksmith', query: {tab: 'weapon'} }" exact class="nav-link">
        <div class="icon"><img src="../assets/navbar-icons/blacksmith-icon.png" class="ui-link-icon" alt="Blacksmith">
        </div>
        <div class="link-text">{{ $t("viewLink.blacksmith") }}</div>
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

    <li class="top-nav-links">
      <a :href="BazaarLink()" class="nav-link" target="_blank">
        <div class="icon"><img src="../assets/navbar-icons/bazaar-icon.png" class="ui-link-icon" alt="Bazaar"></div>
        <div class="link-text d-flex  justify-content-center align-items-center">
          {{ $t("viewLink.bazaar") }}
          <b-icon-box-arrow-up-right scale="0.8"/>
        </div>
      </a>
    </li>

    <li class="top-nav-links" id="update-notifications" href=# tabindex="0">
      <a class="nav-link" target="_blank">
        <div class="icon">
          <img src="../assets/navbar-icons/updates.svg" class="ui-link-icon gold-icon" alt="Updates">
          <span v-if="unreadUpdates" class="icon__badge" @refresh-unread-updates="refreshUnreadUpdates">{{unreadUpdates}}</span>
        </div>
        <div class="link-text">{{ $t("viewLink.updates") }}</div>
        <update-popup/>
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

<script lang="ts">
import {portal, pvp, quests, raid} from '@/feature-flags';
import {mapGetters, mapState} from 'vuex';
import Vue from 'vue';

import Hint from '@/components/Hint.vue';
import UpdatePopup from './UpdatePopup.vue';

interface Data {
  raid: boolean,
  portal: boolean,
  pvp: boolean,
  quests: boolean,
  unreadUpdates: number,
}

export default Vue.extend({
  data() {
    return {
      raid,
      portal,
      pvp,
      quests,
      unreadUpdates: 0,
    } as Data;
  },

  computed: {
    ...mapState(['defaultAccount']),
    ...mapGetters([
      'getCurrentChainSupportsPvP',
      'getCurrentChainSupportsQuests',
      'getHasAdminAccess',
      'getHasMinterAccess',
    ]),
    supportsPvP(): boolean {
      return this.getCurrentChainSupportsPvP;
    },
    supportsQuests(): boolean {
      return this.getCurrentChainSupportsQuests;
    },
    hasAdminAccess(): boolean {
      return this.getHasAdminAccess || this.getHasMinterAccess;
    },
  },
  components: {
    Hint,
    UpdatePopup,
  },
  methods: {
    BazaarLink() {
      return process.env.VUE_APP_BAZAAR_URL || 'https://bazaar.market/';
    },

    refreshUnreadUpdates(unreadUpdates: any) {
      console.log('unreadUpdates: ', unreadUpdates, this.unreadUpdates);
      this.unreadUpdates = unreadUpdates;
    }
  },
});
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Oswald:wght@200;300;400;500;600;700&display=swap');

a {
  font-weight: bold;
}

.gold-icon {
  filter: invert(81%) sepia(97%) saturate(276%) hue-rotate(317deg) brightness(97%) contrast(91%);
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
  font-size: clamp(.5rem, 1vw, 1rem);
  color: #ffffff;
}

.link-text > svg{
  margin-top: -1px;
  margin-left: 5px;
}

.play-to-earn-btn{
  display: flex;
  flex-direction: column;
  height: 100%;
  margin-right: 15px;
  align-items: center;
  vertical-align: middle;
  justify-content: center;
  background-image: url('../assets/btn-long.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  object-fit: fill;
  padding: 10px 40px 10px 40px;
  border: none;
  font-family: Oswald;
  color: #fff;
  font-size: 17px;
  margin: auto;
  margin-right: -40px;
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
  display: revert;
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

#update-notifications > a > div > .icon__badge {
  position: absolute;
  bottom: 25px;
  right: 15px;
  background: red;
  color: white;
  width: 20px;
  height: 18px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
}

#update-notifications > .nav-link {
  cursor: pointer;
}

#update-notifications {
  position: relative;
  display: flex;
}

@media (max-width: 1366px) {
  .play-to-earn > div {
    text-align: center;
    width: 176px;
  }
}

</style>
