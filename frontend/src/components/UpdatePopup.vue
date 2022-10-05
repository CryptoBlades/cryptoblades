<template>
  <b-popover custom-class="h-50 overflow-auto" target="update-notifications" placement="bottom" triggers="click">
    <!-- <span>THIS IS A TEST</span>
    <span>{{updateNotifications}}</span> -->
    <div v-for="update in updateNotifications" :key="update.hash">
      <Update :hash="update.hash" :link="update.link" :title="update.title"/>
    </div>
  </b-popover>
</template>

<script lang='ts'>
import { apiUrl } from '@/utils/common';
import Vue from 'vue';
import Update from '@/components/Update.vue';

interface Data {
  updateNotifications: Notification[],
}

interface Notification {
  hash: string,
  title: string,
  link: string,
  timestamp: number,
}

export default Vue.extend({
  data() {
    return {
      updateNotifications: [],
    } as Data;
  },

  methods: {
    BazaarLink() {
      return process.env.VUE_APP_BAZAAR_URL || 'https://bazaar.market/';
    },

    async getUpdateNotifications() {
      console.log('getUpdateNotifications');
      const response = await fetch(apiUrl('static/notifications'));
      const notifications = await response.json() as Notification[];
      const updatesOrderedByTimestamp = notifications.sort((a, b) => {
        return a.timestamp - b.timestamp;
      });
      const topNotifications = updatesOrderedByTimestamp.slice(0, 10);
      this.updateNotifications = topNotifications;
    },

    /**
     * current checkNotifications method
     * Grabs notifications from the API correctly but then immediately sets a localStorage variable
     * that prevents any more from being shown again.
     *
     */
    async checkNotifications() {
      const response = await fetch(apiUrl('static/notifications'));
      const notifications = await response.json() as Notification[];
      // const updatesOrderedByTimestamp = notifications.sort((a, b) => {
      //   return a.timestamp - b.timestamp;
      // });

      //updatesOrderedByTimestamp.slice(0, 10);
      // console.log(notifications);
      // console.log(notifications[0].link);

      const lastHash = localStorage.getItem('lastnotification');
      // console.log(lastHash);
      let shouldContinue = true;

      notifications.forEach((notification: Notification) => {
        if (!shouldContinue) return;

        if (lastHash === notification.hash) {
          shouldContinue = false;
          return;
        }

        (this as any).$dialog.notify.warning(
          `${notification.title}
          <br>
          <a href="${notification.link}" target="_blank">Check it out!</a>
          `,
          {
            timeout: 300000,
          },
        );
      });

      localStorage.setItem('lastnotification', notifications[0].hash);
    },
  },

  async created() {
    this.getUpdateNotifications();
  },

  components: {
    Update,
  },
});
</script>

<style scoped>

</style>
