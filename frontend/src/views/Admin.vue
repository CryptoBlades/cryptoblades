<template>
  <b-tabs v-if="hasAccessToAnyTab" justified content-class="mt-3"> <!-- note, use "vertical" if too many tabs -->
    <AdminTab v-for="tab in tabs" :key="tab.title" :title="tab.title" :contract="tab.contract"
              :component="tab.component"/>
  </b-tabs>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import {Contract} from '@/interfaces';
import AdminTab from '@/components/smart/AdminTab.vue';

interface StoreMappedActions {
  userHasAnyAdminAccess(): Promise<boolean>;

  userHasAnyMinterAccess(): Promise<boolean>;
}

interface Tab {
  title: string;
  contract: Contract<any>;
  component: string;
}

interface Data {
  hasAccessToAnyTab: boolean;
  tabs: Tab[];
}

export default Vue.extend({
  components: {AdminTab},

  computed: {
    ...mapGetters(['contracts']),
    ...mapState(['defaultAccount']),
  },

  data() {
    return {
      hasAccessToAnyTab: false,
      tabs: [] as Tab[],
    } as Data;
  },

  methods: {
    ...mapActions(['userHasAnyAdminAccess', 'userHasAnyMinterAccess']) as StoreMappedActions,

    async fetchData() {
      this.hasAccessToAnyTab = await this.userHasAnyAdminAccess() || await this.userHasAnyMinterAccess();
    },
  },

  async mounted() {
    this.tabs.push({
      title: 'quests',
      contract: this.contracts.SimpleQuests,
      component: 'QuestsAdmin',
    });
    this.tabs.push({
      title: 'cbkLand',
      contract: this.contracts.CBKLand,
      component: 'CBKLandAdmin',
    });
    this.tabs.push({
      title: 'weapons',
      contract: this.contracts.Weapons,
      component: 'WeaponsAdmin',
    });
    this.tabs.push({
      title: 'burningManager',
      contract: this.contracts.BurningManager,
      component: 'BurningManagerAdmin',
    });
    await this.fetchData();
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
</style>
