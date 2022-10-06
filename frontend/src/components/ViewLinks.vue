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

    <li v-if="hasAdminAccess" class="top-nav-links">
      <router-link :to="{ name: 'admin' }" exact class="nav-link">
        <div class="icon"><img src="../assets/navbar-icons/gear-icon.png" class="ui-link-icon" alt="Admin"></div>
        <div class="link-text">{{ $t("viewLink.admin") }}</div>
      </router-link>
    </li>

    <li class="top-nav-links" id="update-notifications" > <!-- v-for="update in getUpdateNotifications" :key="update.hash"> -->
      <a class="nav-link" target="_blank">
        <div class="icon">
          <img src="../assets/navbar-icons/bazaar-icon.png" class="ui-link-icon" alt="Bazaar">
          <span class="unreadUpdates"/>
        </div>
        <div class="link-text">{{ $t("viewLink.updates") }}</div>
        <update-popup/>
      </a>
    </li>
    <!-- <div v-else v-for="quest in walletQuests" :key="quest.id" class="d-flex w-100">
      <QuestRow :quest="quest" :questTemplateType="QuestTemplateType.WALLET"
                :reputationLevelRequirements="reputationLevelRequirements"
                @refresh-quest-data="onRefreshQuestData"/>
    </div> -->

  </b-navbar-nav>
</template>

<script lang="ts">
// import { apiUrl } from '@/utils/common';
import {portal, pvp, quests, raid} from '@/feature-flags';
import {mapGetters, mapState} from 'vuex';
import Vue from 'vue';

import Hint from '@/components/Hint.vue';
import UpdatePopup from './UpdatePopup.vue';
// import Update from '@/components/Update.vue';

interface Data {
  raid: boolean,
  portal: boolean,
  pvp: boolean,
  quests: boolean,
  //updateNotifications: Notification[],
}

// interface Notification {
//   hash: string,
//   title: string,
//   link: string,
//   timestamp: number,
// }

export default Vue.extend({
  data() {
    return {
      raid,
      portal,
      pvp,
      quests,
      //updateNotifications: [],
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
    //Update,
  },
  methods: {
    BazaarLink() {
      return process.env.VUE_APP_BAZAAR_URL || 'https://bazaar.market/';
    },

    // async getUpdateNotifications() {
    //   console.log('getUpdateNotifications');
    //   const response = await fetch(apiUrl('static/notifications'));
    //   const notifications = await response.json() as Notification[];
    //   const updatesOrderedByTimestamp = notifications.sort((a, b) => {
    //     return a.timestamp - b.timestamp;
    //   });
    //   const topNotifications = updatesOrderedByTimestamp.slice(0, 10);
    //   this.updateNotifications = topNotifications;
    //   //return topNotifications;
    // },

    /**
     * current checkNotifications method
     * Grabs notifications from the API correctly but then immediately sets a localStorage variable
     * that prevents any more from being shown again.
     *
     */
    // async checkNotifications() {
    //   const response = await fetch(apiUrl('static/notifications'));
    //   const notifications = await response.json() as Notification[];
    //   // const updatesOrderedByTimestamp = notifications.sort((a, b) => {
    //   //   return a.timestamp - b.timestamp;
    //   // });

    //   //updatesOrderedByTimestamp.slice(0, 10);
    //   // console.log(notifications);
    //   // console.log(notifications[0].link);

    //   const lastHash = localStorage.getItem('lastnotification');
    //   // console.log(lastHash);
    //   let shouldContinue = true;

    //   notifications.forEach((notification: Notification) => {
    //     if (!shouldContinue) return;

    //     if (lastHash === notification.hash) {
    //       shouldContinue = false;
    //       return;
    //     }

    //     (this as any).$dialog.notify.warning(
    //       `${notification.title}
    //       <br>
    //       <a href="${notification.link}" target="_blank">Check it out!</a>
    //       `,
    //       {
    //         timeout: 300000,
    //       },
    //     );
    //   });

    //   localStorage.setItem('lastnotification', notifications[0].hash);
    // },
  },
  // async created() {
  //   this.getUpdateNotifications();
  // },
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

.unreadUpdates {
  position: absolute;
  bottom: -10px;
  right: -10px;
  padding: 5px 10px;
  border-radius: 50%;
  background: red;
  z-index: 10;
}

#update-notifications > .nav-link {
  cursor: pointer;
}

@media (max-width: 1366px) {
  .play-to-earn > div {
    text-align: center;
    width: 176px;
  }
}

</style>
