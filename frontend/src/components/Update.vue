<template>
<!-- if isRead, toggle classes read and isReadBadge? -->
  <b-link :class="this.isRead ? 'read': 'unread'" :id="this.hash" :href="this.link"
    target="_blank" @click="updateIsRead">
    <span :class="this.isRead ? 'read__badge' : 'unread__badge'"></span>
    <span class="notification-title">{{this.title}}</span>
  </b-link>

  <!-- <a :href="this.link" target="_blank" class="w-100 d-inline-flex mt-1 mb-1"> -->
    <!-- <b-checkbox class="isRead" :id="'checkbox' + this.hash" :checked="this.isRead"
      :disabled="isDisabled" :value="this.isRead" @change="updateIsRead($event)">
    </b-checkbox> -->

    <!-- <div class="update-title" @click="updateIsRead(true)">
      <span>{{this.title}}</span>
    </div>
  </a> -->
</template>

<script lang="ts">
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
    isRead: {
      type: Boolean as PropType<boolean | undefined>,
    }
  },
  data(){
    return {};
  },
  computed: {
    // isDisabled(): boolean {
    //   return !!this.isRead;
    // }
  },
  methods: {
    /**
     * updates the checkbox for the notification
     * checked if read/marked
     */
    updateIsRead() {
      if (!this.isRead) {
        this.$emit('update:isRead', true);
        this.$emit('refresh-update-popup');
      }
    }
  },
  components: {},
  async created() {
  },
});
</script>

<style scoped>
.read > .notification-title {
  color: #ccc;
}

.unread > .notification-title {
  color: #EDCD90;
}

.unread {
  display: flex;
  align-items: center;
  margin-bottom: 5px;
}

.read {
  display: flex;
  align-items: center;
  margin-bottom: 5px;
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
  top:4px;
}

.read__badge:after {
  content:"";
  position: absolute;
  width:3px;
  height:3px;
  background-color:#ccc;
  left:2px;
  top:10px;
}
</style>
