<template>
  <div class="bg-dark">
    <b-checkbox id="markAllAsRead" class="mb-1" @change="setAllAsRead($event)"
      :value="this.readAll" :checked="this.readAll" :disabled="isDisabled">
      {{$t("updates.markAllAsRead")}}
    </b-checkbox>
    <div v-for="update in updateNotifications" :key="update.hash">
      <Update :hash="update.hash" :link="update.link" :title="update.title"
        v-bind:isRead.sync="update.isRead"
        @refresh-update-popup="refreshUpdatePopup"/>
    </div>
  </div>
</template>


<script lang='ts'>
import { apiUrl } from '@/utils/common';
import Vue from 'vue';
import Update from '@/components/Update.vue';

interface Data {
  updateNotifications: Notification[],
  readAll: boolean,
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
      readAll: false,
    } as Data;
  },
  computed: {
    isDisabled(): boolean {
      return !!this.readAll;
    }
  },
  methods: {
    /**
     * Mark all notifications as read
     */
    setAllAsRead(isReadAllClicked: any) {
      this.readAll = isReadAllClicked;
      this.updateNotifications.forEach((notification) => {
        notification.isRead = true;
      });
      this.updateStorage();
    },

    /**
     * Check if there are any elements that aren't currently read
     */
    isEveryUpdateRead() {
      const unreadUpdate = this.updateNotifications.find((notification) => !notification.isRead);
      if (!unreadUpdate) {
        this.readAll = true;
      }
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
      const storageNotifications = localStorage.getItem('updateNotifications');
      if (storageNotifications) {
        return JSON.parse(storageNotifications);
      }
      return [];
    },

    /**
     * Update the storage and check if all
     * notifications are now marked as read.
     * If so, change markAllAsRead checkbox to true,
     */
    refreshUpdatePopup() {
      this.updateStorage();
      this.isEveryUpdateRead();
    },
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
  #markAllAsRead {
    color: #EDCD90;
  }
  #markAllAsRead:hover {
    text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #e1bb34, 0 0 10px #e1bb34;
  }

</style>
