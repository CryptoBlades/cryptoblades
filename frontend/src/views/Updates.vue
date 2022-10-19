<template>
  <div class="bg-dark">
    <div class="notification-header">
      <span>{{$t("updates.notifications")}}</span>
      <b-button id="markAllAsRead"
        v-bind:readAll.sync="this.readAll"
        @click="setAllAsRead">{{$t("updates.markAllAsRead")}}
      </b-button>
    </div>
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
import { INotification } from '@/interfaces';

interface Data {
  updateNotifications: INotification[],
  readAll: boolean,
}

export default Vue.extend({
  data() {
    return {
      updateNotifications: [],
      readAll: false,
    } as Data;
  },
  computed: {},
  methods: {
    /**
     * Mark all notifications as read
     */
    setAllAsRead() {
      if (!this.readAll)
      {
        this.readAll = true;
        this.updateNotifications.forEach((notification) => {
          notification.isRead = true;
        });
        this.$emit('refresh-update-popup');
        this.updateStorage();
      }
    },

    /**
     * Check if there are any elements that aren't currently read
     */
    isEveryUpdateRead() {
      const unreadUpdate = this.updateNotifications.find((notification) => !notification.isRead);
      if (!unreadUpdate) {
        this.readAll = true;
        this.$emit('refresh-update-popup');
      }
    },

    /**
     * Check for updates from API. If there are new notifications from the API
     * then we add them to the front of the user's notifications on localStorage.
     * If this is the user's first time, we add fresh API data to localStorage.
     */
    async checkForNotificationUpdatesFromAPI() {
      const notificationsFromAPI = await this.getNotificationsFromAPI();
      this.getStorage();
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
      const notifications = await response.json() as INotification[];
      const updatesOrderedByTimestamp = notifications.sort((a, b) => {
        return a.timestamp - b.timestamp;
      });
      const topNotifications = updatesOrderedByTimestamp.slice(0, 10);
      return topNotifications;
    },

    /**
     * set the notifications from the API
     */
    async setUpdateNotificationsFromAPI(notificationsFromAPI: INotification[]) {
      this.updateNotifications = notificationsFromAPI;
      this.updateStorage();
    },

    /**
     * update localStorage with new notification data.
     * stored data is of the form
     * {updateNotifications: INotification[], readAll: boolean}
     */
    updateStorage() {
      const storageData = {updateNotifications: this.updateNotifications, readAll: this.readAll};
      localStorage.setItem('updateNotifications', JSON.stringify(storageData));
      console.log(localStorage.getItem('updateNotifications'));
    },

    /**
     * get localStorage data stored in the form
     * {updateNotifications: INotification[], readAll: boolean}
     */
    getStorage() {
      const storageNotifications = localStorage.getItem('updateNotifications');
      if (storageNotifications) {
        const {updateNotifications, readAll} = JSON.parse(storageNotifications);
        this.updateNotifications = updateNotifications;
        this.readAll = readAll;
      }
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
    cursor: pointer;
    outline: none;
    border: 0;
    box-shadow: none;
    background-color: transparent;
  }
  #markAllAsRead:hover {
    text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #e1bb34, 0 0 10px #e1bb34;
  }

  .notification-header {
    margin-bottom: 10px;
    padding-bottom: 5px;
    display: flex;
    justify-content: space-between;
    border-bottom: 1px solid;
    border-bottom-color: #EDCD90;
  }
  .notification-header > span {
    text-align: center;
    font-size: 1rem;
    display: flex;
    padding: 0.375rem 0.75rem;
  }

</style>
