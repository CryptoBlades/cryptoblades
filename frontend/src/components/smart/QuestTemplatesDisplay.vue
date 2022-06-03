<template>
  <div>
    <h2>{{$t(`quests.questTemplateType.${QuestTemplateType[questTemplateType]}`)}} {{ $t('quests.templates')}}</h2>
    <b-form-group class="m-3">
      <b-form-radio v-model="questTemplateType" @change="refreshQuestTemplates" :value="QuestTemplateType.QUEST">
        {{ $t('quests.questsTitle') }}
      </b-form-radio>
      <b-form-radio v-model="questTemplateType" @change="refreshQuestTemplates" :value="QuestTemplateType.PROMO">
        {{ $t('quests.questTemplateType.PROMO') }}
      </b-form-radio>
      <b-form-radio v-model="questTemplateType" @change="refreshQuestTemplates" :value="QuestTemplateType.WALLET">
        {{ $t('quests.questTemplateType.WALLET') }}
      </b-form-radio>
      <b-form-radio v-model="questTemplateType" @change="refreshQuestTemplates" :value="QuestTemplateType.PICKABLE">
        {{ $t('quests.questTemplateType.PICKABLE') }}
      </b-form-radio>
    </b-form-group>
    <b-form inline>
      <label class="mr-sm-2">{{ $t('quests.templatesTier') }}</label>
      <b-form-select class="mt-2 mb-2" v-model="templatesTier" @change="refreshQuestTemplates">
        <b-form-select-option :value="undefined" disabled>
          {{ $t('quests.pleaseSelectQuestTier') }}
        </b-form-select-option>
        <b-form-select-option v-for="tier in tiers" :key="tier" :value="tier">
          {{ $t(`quests.rarityType.${Rarity[tier]}`) }}
        </b-form-select-option>
      </b-form-select>
    </b-form>
    <QuestsList v-if="templatesTier !== undefined" :tier="questTemplateTier" deletable/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {Quest, Rarity, QuestTemplateType} from '@/views/Quests.vue';
import QuestsList from './QuestsList.vue';

interface StoreMappedActions {
  getQuestTemplates(payload: { tier: number }): Promise<Quest[]>;

  getQuestDeadline(payload: { questID: number }): Promise<number>;

  getQuestSupply(payload: { questID: number }): Promise<number>;
}

interface Data {
  tiers: Rarity[];
  questTemplates: Quest[];
  templatesTier?: Rarity;
  isLoading: boolean;
  questTemplateType: QuestTemplateType;
}

export default Vue.extend({

  components: {QuestsList},

  data() {
    return {
      tiers: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      questTemplates: [],
      templatesTier: undefined,
      QuestTemplateType,
      questTemplateType: QuestTemplateType.QUEST,
      isLoading: false,
      Rarity,
    } as Data;
  },
  computed: {
    questTemplateTier(): number | undefined {
      if(!this.templatesTier) {
        return undefined;
      }
      else if(this.questTemplateType === QuestTemplateType.PROMO) {
        return this.templatesTier + 10;
      }
      else if(this.questTemplateType === QuestTemplateType.PICKABLE) {
        return this.templatesTier + 20;
      }
      else if(this.questTemplateType === QuestTemplateType.WALLET) {
        return this.templatesTier + 30;
      }
      else {
        return this.templatesTier;
      }
    }
  },
  methods: {
    ...mapActions([
      'getQuestTemplates',
      'getQuestDeadline',
      'getQuestSupply',
    ]) as StoreMappedActions,

    async refreshQuestTemplates() {
      if (!this.templatesTier|| !this.questTemplateTier) return;
      try {
        this.isLoading = true;
        this.questTemplates = await this.getQuestTemplates({tier: this.questTemplateTier});
        for (const quest of this.questTemplates) {
          quest.deadline = +await this.getQuestDeadline({questID: quest.id});
          quest.supply = +await this.getQuestSupply({questID: quest.id});
        }
      } finally {
        this.isLoading = false;
      }
    },
  },

  async mounted() {
    await this.refreshQuestTemplates();
    this.$root.$on('refresh-quest-templates', async () => {
      await this.refreshQuestTemplates();
    });
  }

});
</script>

<style scoped>
</style>
