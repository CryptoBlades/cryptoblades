<template>
  <b-popover custom-class="bg-dark h-50 overflow-auto" target="update-notifications"
    placement="bottom" triggers="click blur"> <!-- triggers="click" -->
    <updates/>
  </b-popover>
</template>

<script lang='ts'>
import Vue from 'vue';
import Updates from '@/views/Updates.vue';

export default Vue.extend({
  components: {
    Updates,
  },
});
</script>

<style scoped>
</style>
