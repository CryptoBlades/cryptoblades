<template>
  <div class="bg-dark">
    <div class="notification-header">
      <span>{{$t("updates.notifications")}}</span>
      <b-button id="markAllAsRead"
        v-bind:readAll.sync="this.readAll"
        @click="setAllUpdateNotificationsAsRead">{{$t("updates.markAllAsRead")}}
      </b-button>
    </div>
    <div v-for="update in updateNotifications" :key="update.hash">
      <Update :hash="update.hash" :link="update.link" :title="update.title"
        :timestamp="update.timestamp" v-bind:isRead.sync="update.isRead"
        @refresh-update-popup="refreshUpdatePopup"/>
    </div>
  </div>
</template>

<script lang='ts'>
import Vue, { PropType } from 'vue';
import Update from '@/components/Update.vue';
import { INotification } from '@/interfaces';

export default Vue.extend({
  props: {
    notificationsFromAPI: {
      type: Array as PropType<INotification[]>,
      default() {
        return [];
      },
    },
    updateNotifications: {
      type: Array as PropType<INotification[]>,
      default() {
        return [];
      },
    },
    readAll: {
      type: Boolean as PropType<boolean | undefined>,
    },
  },
  methods: {
    setAllUpdateNotificationsAsRead() {
      if (!this.readAll)
      {
        this.$emit('update:readAll', true);
        this.updateNotifications.forEach((notification) => {
          notification.isRead = true;
        });
        this.$emit('refresh-update-popup');
        this.updateStorageOfUpdateNotifications();
      }
    },

    isEveryUpdateRead() {
      const unreadUpdate = this.updateNotifications.find((notification) => !notification.isRead);
      if (!unreadUpdate) {
        this.$emit('update:readAll', true);
        this.$emit('refresh-update-popup');
      }
    },

    /**
     * If there are new notifications from the API then we add them
     * to the front of the user's notifications on localStorage.
     * If this is the user's first time, we add fresh API data to localStorage.
     */
    async checkForNotificationUpdatesFromAPI() {
      const notificationChanges = [];

      if (this.updateNotifications.length > 0) {
        let j = 0;
        for(let i = 0; i < this.notificationsFromAPI.length; i++) {
          if (this.notificationsFromAPI[i].hash !== this.updateNotifications[i + j].hash) {
            notificationChanges.push(this.notificationsFromAPI[i]);
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
        this.setUpdateNotificationsFromAPI(this.notificationsFromAPI);
      }
    },

    async setUpdateNotificationsFromAPI(notificationsFromAPI: INotification[]) {
      this.$emit('update:updateNotifications', notificationsFromAPI);
      this.updateStorageOfUpdateNotifications();
    },

    /**
     * update localStorage with new notification data.
     * stored data is of the form
     * {updateNotifications: INotification[], readAll: boolean}
     */
    updateStorageOfUpdateNotifications() {
      const storageData = {updateNotifications: this.updateNotifications, readAll: this.readAll};
      localStorage.setItem('updateNotifications', JSON.stringify(storageData));
    },

    refreshUpdatePopup() {
      this.updateStorageOfUpdateNotifications();
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
    border-bottom: 1px solid #EDCD90;
  }
  .notification-header > span {
    text-align: center;
    font-size: 1rem;
    display: flex;
    padding: 0.375rem 0.75rem;
  }

</style>
