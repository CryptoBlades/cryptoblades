<template>
  <div class="w-100">
    <div class="update-hash">
      <span>{{this.hash}}</span>
    </div>
    <div class="update-title">
      <span>{{this.title}}</span>
    </div>
    <div class="update-link">
      <span>{{this.link}}</span>
    </div>
    <div class="update-test">
      <span>{{this.test}}</span>
    </div>
  </div>
</template>

<script lang="ts">
// import { apiUrl } from '@/utils/common';
import Vue, { PropType } from 'vue';

// interface Notification {
//   hash: string,
//   title: string,
//   link: string,
// }

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
    // isRead: {
    //   type: Boolean as PropType<boolean>,
    // }
  },
  data(){
    return {
      test: 'test Value',
      isRead: false,
    };
  },
  computed: {},
  methods: {
    // /**
    //  * current checkNotifications method
    //  * Grabs notifications from the API correctly but then immediately sets a localStorage variable
    //  * that prevents any more from being shown again.
    //  *
    //  */
    // async checkNotifications() {
    //   const response = await fetch(apiUrl('static/notifications'));
    //   const notifications = await response.json();
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
});
</script>

<style scoped>
  .update-title > span {
    color: black;
  }
  .update-link > span {
    color: black;
  }
</style>
