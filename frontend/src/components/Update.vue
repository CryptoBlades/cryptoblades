<template>
<!-- TODO: implement link-prevue -->
  <a :href="this.link" target="_blank" class="w-100">
    <b-checkbox class="isRead" :id="'checkbox' + this.hash" :checked="this.isRead"
      :disabled="isDisabled" :value="this.isRead" @change="updateIsRead($event)">
    </b-checkbox>
    <div class="update-title">
      <span>{{this.title}}</span>
    </div>
  </a>
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
    isDisabled(): boolean {
      return !!this.isRead;
    }
  },
  methods: {
    /**
     * updates the checkbox for the notification
     * checked if read/marked
     */
    updateIsRead(isReadClicked: any) {
      console.log(isReadClicked, this);
      this.$emit('update:isRead', isReadClicked);
      this.$emit('refresh-update-popup');
    }
  },
  components: {},
  async created() {

  },
});
</script>

<style scoped>
  .update-title > span {
    color: black;
  }
  /* .isRead:checked {
    pointer
  } */
</style>
