<template>
  <b-tabs v-if="hasAccessToAnyTab" justified content-class="mt-3"> <!-- note, use "vertical" if too many tabs -->
    <b-tab :disabled="!hasQuestsAccess">
      <template #title>
        {{ $t('quests.questsTitle') }}
        <hint v-if="!hasQuestsAccess" :text="$t('admin.doNotHaveAccessTooltip')"/>
      </template>
      <QuestsDashboard v-if="hasQuestsAccess"/>
    </b-tab>
  </b-tabs>
</template>

<script lang="ts">
import Vue from 'vue';
import QuestsDashboard from '@/components/smart/QuestsDashboard.vue';
import {mapActions, mapState} from 'vuex';
import Hint from '@/components/Hint.vue';

interface StoreMappedActions {
  userHasQuestsAdminAccess(): Promise<boolean>;

  userHasAdminAccess(): Promise<boolean>;
}

interface Data {
  hasAccessToAnyTab: boolean;
  hasQuestsAccess: boolean;
}

export default Vue.extend({
  components: {QuestsDashboard, Hint},

  computed: {
    ...mapState(['defaultAccount']),
  },

  data() {
    return {
      hasAccessToAnyTab: false,
      hasQuestsAccess: false,
    } as Data;
  },

  methods: {
    ...mapActions(['userHasQuestsAdminAccess', 'userHasAdminAccess']) as StoreMappedActions,

    async fetchData() {
      this.hasQuestsAccess = await this.userHasQuestsAdminAccess();
      this.hasAccessToAnyTab = await this.userHasAdminAccess();
    },
  },

  async mounted() {
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
