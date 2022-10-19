<template>
  <!-- TODO: need to rework class naming/etc... -->
  <div class="top-nav-links" ref="updateNotifications" id="update-notifications" href=# tabindex="0">
    <a class="nav-link" target="_blank">
      <div class="icon">
        <img src="../assets/navbar-icons/updates.svg" class="ui-link-icon gold-icon" alt="Updates">
        <span v-if="this.unreadNotifications" class="icon__badge"/>
      </div>
      <b-popover custom-class="bg-dark h-50 overflow-auto" :target="() => $refs.updateNotifications"
        placement="bottom" triggers="click blur"> <!-- triggers="click" -->
        <updates @refresh-update-popup="refreshUpdatePopup"/>
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
}

export default Vue.extend({
  data() {
    return {
      unreadNotifications: false,
    } as Data;
  },
  components: {
    Updates,
  },
  methods: {
    /**
     * refresh icon after reading all notifs
     */
    refreshUpdatePopup() {
      if (this.unreadNotifications) {
        this.unreadNotifications = false;
      }
    },

    /**
     * TODO: need to add logic here to check if there are any new
     * notifications yet. This will proc the indicator icon
     */
    async checkNotifications() {
      const currentNotifications = this.getStorage() as INotification[];
      if (currentNotifications.length === 0 || currentNotifications.find((x) => x.isRead !== true)) {
        this.unreadNotifications =  true;
        return;
      }
      const apiNotifications = await this.getNotificationsFromAPI();
      if (apiNotifications[0].hash !== currentNotifications[0].hash) {
        this.unreadNotifications =  true;
        return;
      }
      this.unreadNotifications =  false;
    },

    /**
     * get updateNotifications property of locally saved data
     * from localStorage, see getStorage() in Updates.vue
     */
    getStorage() {
      const storageNotifications = localStorage.getItem('updateNotifications') ?? '';
      if (storageNotifications) {
        const {updateNotifications} = JSON.parse(storageNotifications);
        return updateNotifications as INotification[];
      }
      return [];
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
  },
  async created() {
    await this.checkNotifications();
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
}

#update-notifications > .nav-link {
  cursor: pointer;
}

#update-notifications {
  position: relative;
  display: flex;
}

.top-nav-links .nav-link {
  padding: 0;
}

div .nav-link {
  text-transform: uppercase;
  font-weight: 500;
  text-align: center;
  display: revert;
}

div .nav-link .icon {
  padding-bottom: 0.5rem;
}

.ui-link-icon {
  height: 1.5rem;
  margin-top: 5px;
}
</style>
