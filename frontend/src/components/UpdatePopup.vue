<template>
  <div class="top-notification-wrapper" ref="updateNotifications" id="update-notifications" href=# tabindex="0">
    <a class="notification-wrapper" target="_blank">
      <div class="icon">
        <img src="../assets/updates.svg" class="ui-notification-icon gold-icon"
          :class="this.unreadNotifications ? 'ring' : ''" alt="Updates">
        <span v-if="this.unreadNotifications" class="icon__badge"/>
      </div>
      <b-popover custom-class="bg-dark h-50 overflow-auto" :target="() => $refs.updateNotifications"
        placement="bottom" triggers="click blur">
        <updates :readAll.sync="readAll" :updateNotifications.sync="updateNotifications"
          :notificationsFromAPI="this.apiNotifications" @refresh-update-popup="refreshUpdatePopup"/>
      </b-popover>
    </a>
  </div>
</template>

<script lang='ts'>
import Vue from 'vue';
import Updates from '@/views/Updates.vue';
import { apiUrl } from '@/utils/common';
import { INotification } from '@/interfaces';

interface Data {
  unreadNotifications: boolean,
  readAll: boolean,
  apiNotifications: INotification[],
  updateNotifications: INotification[]
}

export default Vue.extend({
  data() {
    return {
      unreadNotifications: false,
      readAll: false,
      apiNotifications: [],
      updateNotifications: []
    } as Data;
  },
  methods: {
    refreshUpdatePopup() {
      if (this.unreadNotifications) {
        this.unreadNotifications = false;
      }
    },

    getUpdateNotificationsFromStorage() {
      const storageNotifications = localStorage.getItem('updateNotifications') ?? '';
      if (storageNotifications) {
        const {updateNotifications, readAll} = JSON.parse(storageNotifications);
        this.updateNotifications = updateNotifications;
        this.readAll = readAll;
      }
    },

    async checkForNewUpdateNotifications() {
      this.getUpdateNotificationsFromStorage();
      if (this.updateNotifications.length === 0 || this.updateNotifications.find((x) => x.isRead !== true)) {
        this.unreadNotifications =  true;
        return;
      }
      if (this.apiNotifications[0].hash !== this.updateNotifications[0].hash) {
        this.unreadNotifications =  true;
        return;
      }
      this.unreadNotifications =  false;
    },

    async getUpdateNotificationsFromAPI() {
      const response = await fetch(apiUrl('static/notifications'));
      const notifications = await response.json() as INotification[];
      const updatesOrderedByTimestamp = notifications.sort((a, b) => {
        return b.timestamp - a.timestamp;
      });
      const topNotifications = updatesOrderedByTimestamp.slice(0, 10);
      return topNotifications;
    },

  },
  async created() {
    this.apiNotifications = await this.getUpdateNotificationsFromAPI();
    await this.checkForNewUpdateNotifications();
  },
  components: {
    Updates,
  },
});
</script>

<style scoped>
.gold-icon {
  filter: invert(81%) sepia(97%) saturate(276%) hue-rotate(317deg) brightness(97%) contrast(91%);
}

#update-notifications > a > div > .icon__badge {
  position: absolute;
  bottom: 10px;
  right: 5px;
  background: red;
  color: white;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  animation: w3-alert-red 1.6s infinite;
}

#update-notifications > .notification-wrapper {
  cursor: pointer;
}

#update-notifications {
  position: relative;
  display: flex;
}

.top-notification-wrapper .notification-wrapper {
  padding: 0;
}

div .notification-wrapper {
  text-transform: uppercase;
  font-weight: 500;
  text-align: center;
  display: revert;
}

div .notification-wrapper .icon {
  padding-bottom: 0.5rem;
}

.ui-notification-icon {
  height: 1.5rem;
  margin-top: 5px;
}

.ring {
  animation: ring 1.6s linear infinite;
}

@keyframes w3-alert-red {
	0% {
		-webkit-box-shadow: 0 0 0 0 rgba(254, 57, 5, 0.7);
		-moz-box-shadow: 0 0 0 0 rgba(254, 57, 5, 0.7);
		box-shadow: 0 0 0 0 rgba(254, 57, 5, 0.7)
	}
	100% {
		-webkit-box-shadow: 0 0 0 15px rgba(254, 57, 5, 0);
		-moz-box-shadow: 0 0 0 15px rgba(254, 57, 5, 0);
		box-shadow: 0 0 0 15px rgba(254, 57, 5, 0)
	}
}

@keyframes ring {
  0% { transform: rotate(0deg) }
  5% { transform: rotate(0deg) }
  15% { transform: rotate(0deg) }
  25% { transform: rotate(20deg) }
  35% { transform: rotate(-15deg) }
  45% { transform: rotate(10deg) }
  55% { transform: rotate(-5deg) }
  60% { transform: rotate(0deg) }
  100% { transform: rotate(0deg) }
}
</style>
