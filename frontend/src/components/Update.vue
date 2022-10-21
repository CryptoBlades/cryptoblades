<template>
  <b-link :key="`${this.hash}-${this.isRead}`" :class="{read: this.isRead, unread: !this.isRead}" :id="this.hash" :href="this.link"
    target="_blank" @click="updateIsRead">
    <span :class="{read__badge: this.isRead, unread__badge: !this.isRead}"></span>
    <span class="notification-title">{{this.title}}</span>
    <span class="notification-age">{{this.getUpdateAge}}</span>
  </b-link>
</template>

<script lang="ts">
import { secondsToRelativeAge } from '@/utils/date-time';
import Vue, { PropType } from 'vue';

export default Vue.extend({
  props: {
    hash: {
      type: String as PropType<string>,
    },
    title: {
      type: String as PropType<string>,
    },
    link: {
      type: String as PropType<string>,
    },
    timestamp: {
      type: Number as PropType<number>,
    },
    isRead: {
      type: Boolean as PropType<boolean | undefined>,
    }
  },
  computed: {
    /**
     * get the computed age of this update relative to when the user sees it
     */
    getUpdateAge(): string {
      const currentDate = new Date();
      const dateAge = secondsToRelativeAge(+currentDate/1000 - this.timestamp/1000);
      return dateAge + ' ago';
    }
  },
  methods: {
    /**
     * update the read status of this update
     */
    updateIsRead() {
      if (!this.isRead) {
        this.$emit('update:isRead', true);
        this.$emit('refresh-update-popup');
      }
    }
  },
});
</script>

<style scoped>
.read > .notification-title {
  color: #ccc;
  width: 75%;
}

.unread > .notification-title {
  color: #EDCD90;
  width: 75%;
}

.read, .unread {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.read__badge, .unread__badge {
  width: 5%;
}

.unread__badge {
  justify-content: center;
  align-items: center;
  border-radius: 50%;
  background: #EDCD90;
  color: white;
  width: 10px;
  height: 10px;
  display: flex;
  padding-right: 10px;
  margin-right: 5px;
}

.read__badge {
  justify-content: center;
  align-items: center;
  display: flex;
  width: 10px;
  height:10px;
  padding-right: 10px;
  margin-right: 5px;
  -ms-transform: rotate(45deg); /* IE 9 */
  -webkit-transform: rotate(45deg); /* Chrome, Safari, Opera */
  transform: rotate(45deg);
}

.read__badge:before {
  content: "";
  position: absolute;
  width:3px;
  height:9px;
  background-color:#ccc;
  left:5px;
  top:1px;
}

.read__badge:after {
  content:"";
  position: absolute;
  width:3px;
  height:3px;
  background-color:#ccc;
  left:2px;
  top:7px;
}

.notification-age {
  width: 20%
}
</style>
