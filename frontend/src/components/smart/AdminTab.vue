<template>
  <b-tab v-if="initialized" :class="hasTabAccess ? '' : 'disabled'">
    <template #title>
      {{ $t(`admin.tabs.${title}`) }}
      <Hint v-if="!hasTabAccess" :text="$t('admin.doNotHaveAccessTooltip')"/>
    </template>
    <AdminMaker :contract="contract" class=""/>
    <component :is="component"/>
  </b-tab>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapState} from 'vuex';
import {Contract} from '@/interfaces';
import {PropType} from 'vue/types/options';
import AdminMaker from '@/components/smart/AdminMaker.vue';
import QuestsAdmin from '@/components/smart/QuestsAdmin.vue';
import Hint from '@/components/Hint.vue';

interface StoreMappedActions {
  userHasAdminAccess(payload: { contract: Contract<any> }): Promise<boolean>;
}

interface Data {
  hasTabAccess: boolean;
  initialized: boolean;
}

export default Vue.extend({
  components: {Hint, AdminMaker, QuestsAdmin},
  props: {
    title: {
      type: String as PropType<string>,
      required: true,
    },
    contract: {
      type: Object as PropType<Contract<any>>,
      required: true,
    },
    component: {
      type: String as PropType<string>,
      required: true,
    },
  },

  data() {
    return {
      hasTabAccess: false,
      initialized: false,
    } as Data;
  },

  computed: {
    ...mapState(['defaultAccount']),
  },

  methods: {
    ...mapActions(['userHasAdminAccess']) as StoreMappedActions,

    async fetchData() {
      this.hasTabAccess = await this.userHasAdminAccess({contract: this.contract});
    },
  },

  async mounted() {
    await this.fetchData();
    this.initialized = true;
  },

  watch: {
    async defaultAccount(newVal) {
      if (newVal) {
        await this.fetchData();
      }
    },
  }
});
</script>

<style scoped lang="scss">
.disabled {
  color: gray !important;
  pointer-events: none;
}
</style>
