<template>
  <div class="top-nav-links" ref="updateNotifications" id="update-notifications" href=# tabindex="0">
    <a class="nav-link" target="_blank">
      <div class="icon">
        <img src="../assets/navbar-icons/updates.svg" class="ui-link-icon gold-icon" alt="Updates">
        <span class="icon__badge" @refresh-unread-updates="refreshUnreadUpdates"/>
      </div>
      <b-popover custom-class="bg-dark h-50 overflow-auto" :target="() => $refs.updateNotifications"
        placement="bottom" triggers="click blur"> <!-- triggers="click" -->
        <updates/>
      </b-popover>
    </a>
  </div>
</template>

<script lang='ts'>
import Vue from 'vue';
import Updates from '@/views/Updates.vue';

export default Vue.extend({
  components: {
    Updates,
  },
  methods: {
    refreshUnreadUpdates() {
      //console.log('unreadUpdates: ', unreadUpdates, this.unreadUpdates);
      //this.unreadUpdates = unreadUpdates;
    },
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
