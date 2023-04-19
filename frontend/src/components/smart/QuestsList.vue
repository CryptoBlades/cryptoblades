<template>
  <div v-if="isLoading">
    <i class="fas fa-spinner fa-spin"/>
    {{ $t('quests.loading') }}
  </div>
  <div v-else-if="quests.length === 0">
    <h3>
      {{ $t('quests.noQuestTemplatesInSelectedTier') }}
    </h3>
    <div class="ad-container mt-4" v-if="showAds && !isMobile()">
      <script2 async src="https://coinzillatag.com/lib/display.js"></script2>
        <div class="coinzilla" data-zone="C-541621de2f7bb717603"></div>
          <script2>
                window.coinzilla_display = window.coinzilla_display || [];
                var c_display_preferences = {};
                c_display_preferences.zone = "541621de2f7bb717603";
                c_display_preferences.width = "320";
                c_display_preferences.height = "100";
                coinzilla_display.push(c_display_preferences);
          </script2>
    </div>
  </div>
  <div v-else>
    <div v-if="showAds && !isMobile()" class="ad-container mb-4">
      <script2 async src="https://coinzillatag.com/lib/display.js"></script2>
        <div class="coinzilla" data-zone="C-541621de2f7bb717603"></div>
          <script2>
                window.coinzilla_display = window.coinzilla_display || [];
                var c_display_preferences = {};
                c_display_preferences.zone = "541621de2f7bb717603";
                c_display_preferences.width = "320";
                c_display_preferences.height = "100";
                coinzilla_display.push(c_display_preferences);
          </script2>
    </div>
    <div class="available-quests-container d-flex flex-row gap-3 flex-wrap">
      <div v-for="(quest, index) in quests" :key="quest.id" class="quest-row p-3 gap-5">
        <QuestRequirements :quest="quest" :index="index"/>
        <QuestRewards :quest="quest"/>
        <QuestActions
          :quest="quest" :key="quest.id" :deletable="deletable"
          :questTemplateType="questTemplateType" :showActions="false"
          showSupply @refresh-quest-data="fetchQuests"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import { Quest } from '@/interfaces';
import { QuestTemplateType } from '@/enums/Quest';
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
    questTemplateType: {
      type: Number as PropType<QuestTemplateType>,
      required: true,
    },
  },

  data() {
    return {
      quests: [],
      isLoading: false,
      isQuestActionLoading: false,
      showAds: false,
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

    checkStorage() {
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
    }
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
  mounted() {
    this.checkStorage();
  }
});
</script>

<style scoped>
.quest-row {
  display: flex;
  width: 45%;
  background: #141414;
  border: 1px solid #60583E;
  border-radius: 10px;
  align-items: center;
}

.available-quests-container {
  width: fit-content;
  justify-content: center;
}

.quest-row {
    flex-direction: column;
  }
@media (max-width: 992px) {
  .quest-row {
    width: 100%;
  }
}
</style>
