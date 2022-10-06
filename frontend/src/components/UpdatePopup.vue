<template>
  <b-popover custom-class="h-50 overflow-auto" target="update-notifications"
    placement="bottom" triggers="click"> <!-- triggers="click blur" -->
    <b-checkbox class="markAllAsRead" @click="setAllAsRead" >
      {{$t("updates.markAllAsRead")}}
    </b-checkbox>
    <div v-for="update in updateNotifications" :key="update.hash">
      <Update :hash="update.hash" :link="update.link" :title="update.title"
        v-bind:isRead.sync="update.isRead"/>
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
  hash: string;
  title: string,
  link: string,
  timestamp: number,
  isRead: boolean;
}

export default Vue.extend({
  data() {
    return {
      updateNotifications: [],
    } as Data;
  },

  methods: {
    async setAllAsRead() {
      this.updateNotifications.forEach((notification) => {
        notification.isRead = true;
      });
      //const lastHash = localStorage.getItem('lastnotification');
    },

    async checkForNotificationUpdatesFromAPI() {
      const response = await fetch(apiUrl('static/notifications'));
      const notifications = await response.json() as Notification[];
      const updatesOrderedByTimestamp = notifications.sort((a, b) => {
        return a.timestamp - b.timestamp;
      });
      const topNotifications = updatesOrderedByTimestamp.slice(0, 10);

      //compare this to what's currently stored
      //if heads are different, remove head and add, going down the line until
      // hashs match
    },

    async setUpdateNotificationsFromAPI() {
      // const response = await fetch(apiUrl('static/notifications'));
      // const notifications = await response.json() as Notification[];
      // const updatesOrderedByTimestamp = notifications.sort((a, b) => {
      //   return a.timestamp - b.timestamp;
      // });
      // const topNotifications = updatesOrderedByTimestamp.slice(0, 10);
      // check if we currently have anything saved in localStorage,
      // if we do, compare against our hashes and timestamp. Latest gets kicked from storage.
      this.updateNotifications = topNotifications;
      this.updateStorage();
    },

    /**
     * update Notification with hash of updated notification
     */
    updateClientsUpdateNotifications(notification: Notification) {
      //const notif = this.updateNotifications.find((x) => x.hash === notification.hash);
      Object.assign(this.updateNotifications.find((x) => x.hash === notification.hash), notification);
      this.updateStorage();
    },

    /**
     * update localStorage with new notification data
     */
    updateStorage() {
      localStorage.setItem('updateNotifications', JSON.stringify(this.updateNotifications));
    }

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

  async created() {
    console.log('tripped');
    // need to check if data from API has changed from what we have locally
    // await this.checkForNotificationUpdatesFromAPI();
    await this.setUpdateNotificationsFromAPI();
  },
  // async beforeDestroy() {
  //   this.updateStorage();
  // },
  components: {
    Update,
  },
});
</script>

<style scoped>
  .markAllAsRead {
    color: black;
  }

</style>
