<template>
  <div v-if="isLoading">
    <i class="fas fa-spinner fa-spin"/>
    {{ $t('quests.loading') }}
  </div>
  <h3 v-else-if="quests.length === 0">
    {{ $t('quests.noQuestTemplatesInSelectedTier') }} </h3>
  <div v-else class="d-flex flex-column gap-3">
    <div v-for="(quest, index) in quests" :key="quest.id" class="quest-row p-3 gap-5">
      <QuestRequirements :quest="quest" :index="index"/>
      <QuestRewards :quest="quest"/>
      <QuestActions :quest="quest" :key="quest.id" :deletable="deletable" showSupply @refresh-quest-data="fetchQuests"/>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Quest} from '@/views/Quests.vue';
import QuestRequirements from '@/components/smart/QuestRequirements.vue';
import QuestRewards from '@/components/smart/QuestRewards.vue';
import QuestActions from '@/components/smart/QuestActions.vue';
import {mapActions} from 'vuex';

interface StoreMappedActions {
  getQuestTemplates(payload: { tier: number }): Promise<Quest[]>;
}

interface Data {
  quests: Quest[];
  isLoading: boolean;
  isQuestActionLoading: boolean;
}

export default Vue.extend({
  components: {QuestRequirements, QuestRewards, QuestActions},
  props: {
    tier: {
      type: Number as PropType<number>,
      required: true,
    },
    deletable: {
      type: Boolean as PropType<boolean>,
      default: false,
    },
  },

  data() {
    return {
      quests: [],
      isLoading: false,
      isQuestActionLoading: false,
    } as Data;
  },

  methods: {
    ...mapActions([
      'getQuestTemplates',
    ]) as StoreMappedActions,

    async fetchQuests() {
      try {
        this.isLoading = true;
        this.quests = await this.getQuestTemplates({tier: this.tier});
      } finally {
        this.isLoading = false;
      }
    },
  },

  watch: {
    $props: {
      async handler() {
        await this.fetchQuests();
      },
      deep: true,
      immediate: true,
    },
  },
});
</script>

<style scoped>
.quest-row {
  display: flex;
  width: 100%;
  background: #141414;
  border: 1px solid #60583E;
  border-radius: 10px;
  align-items: center;
}

@media (max-width: 576px) {
  .quest-row {
    flex-direction: column;
  }
}
</style>
