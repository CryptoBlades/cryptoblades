<template>
  <b-popover custom-class="h-50 overflow-auto" target="update-notifications"
    placement="bottom" triggers="click"> <!-- triggers="click blur" -->
    <b-checkbox class="markAllAsRead" @click="setAllAsRead" >
      {{$t("updates.markAllAsRead")}}
    </b-checkbox>
    <div v-for="update in updateNotifications" :key="update.hash">
      <Update :hash="update.hash" :link="update.link" :title="update.title"
        v-bind:isRead.sync="update.isRead"
        @refresh-update-popup="updateStorage"/>
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
    /**
     * Mark all notifications as read
     */
    async setAllAsRead() {
      this.updateNotifications.forEach((notification) => {
        notification.isRead = true;
      });
      this.updateStorage();
    },

    /**
     * Check for updates from API. If there are new notifications from the API
     * then we add them to the front of the user's notifications on localStorage.
     * If this is the user's first time, we add fresh API data to localStorage.
     */
    async checkForNotificationUpdatesFromAPI() {
      const notificationsFromAPI = await this.getNotificationsFromAPI();
      this.updateNotifications = this.getStorage();
      const notificationChanges = [];

      if (this.updateNotifications.length > 0) {
        let j = 0;
        for(let i = 0; i < notificationsFromAPI.length; i++) {
          if (notificationsFromAPI[i].hash !== this.updateNotifications[i + j].hash) {
            notificationChanges.push(notificationsFromAPI[i]);
            j++;
          }
          else {
            break;
          }
        }
        if (notificationChanges.length > 0) {
          this.updateNotifications.unshift(...notificationChanges);
          this.setUpdateNotificationsFromAPI(this.updateNotifications.slice(0, 10));
        }
      }
      else {
        this.setUpdateNotificationsFromAPI(notificationsFromAPI);
      }
    },


    /**
     * Get up to the 10 most recent notifications from the API
     */
    async getNotificationsFromAPI() {
      const response = await fetch(apiUrl('static/notifications'));
      const notifications = await response.json() as Notification[];
      const updatesOrderedByTimestamp = notifications.sort((a, b) => {
        return a.timestamp - b.timestamp;
      });
      const topNotifications = updatesOrderedByTimestamp.slice(0, 10);
      return topNotifications;
    },

    async setUpdateNotificationsFromAPI(notificationsFromAPI: Notification[]) {
      this.updateNotifications = notificationsFromAPI;
      this.updateStorage();
    },

    /**
     * update localStorage with new notification data
     */
    updateStorage() {
      localStorage.setItem('updateNotifications', JSON.stringify(this.updateNotifications));
    },

    /**
     * get updateNotifications data from localStorage
     */
    getStorage() {
      return JSON.parse(localStorage.getItem('updateNotifications') ?? '');
    }
  },

  async created() {
    await this.checkForNotificationUpdatesFromAPI();
  },
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
