<template>
  <div>
    <h2>{{ promoQuestTemplates ? $t('quests.createNewPromoQuest') : $t('quests.createNewQuest') }}</h2>
    <b-form-group class="m-3">
      <b-form-radio v-model="promoQuestTemplates" @change="refreshQuestTemplates" :value="false">
        {{ $t('quests.questsTitle') }}
      </b-form-radio>
      <b-form-radio v-model="promoQuestTemplates" @change="refreshQuestTemplates" :value="true">
        {{ $t('quests.promoQuests') }}
      </b-form-radio>
    </b-form-group>
    <b-form class="d-flex flex-column gap-3">
      <div class="grid-container">
        <label class="m-0 align-self-center">{{ $t('quests.questTier') }}</label>
        <div class="d-flex align-items-center gap-3">
          <b-form-select class="mt-2 mb-2" v-model="questTemplate.tier">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectQuestTier') }}
            </b-form-select-option>
            <b-form-select-option v-for="tier in tiers" :key="tier" :value="tier">
              {{ $t(`quests.rarityType.${Rarity[tier]}`) }}
            </b-form-select-option>
          </b-form-select>
        </div>
        <label class="m-0 align-self-center">{{ $t('quests.requirement') }}</label>
        <div class="d-flex align-items-center gap-3">
          <b-form-select class="mt-2 mb-2" v-model="questTemplate.requirementType">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRequirementType') }}
            </b-form-select-option>
            <b-form-select-option v-for="requirementType in requirementTypes" :key="requirementType"
                                  :value="requirementType">
              {{ $t(`quests.requirementType.${RequirementType[requirementType]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-select class="mt-2 mb-2" v-model="questTemplate.requirementRarity">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRequirementRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="requirementRarity in requirementRarities" :key="requirementRarity"
                                  :value="requirementRarity">
              {{ $t(`quests.rarityType.${Rarity[requirementRarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-input v-model="questTemplate.requirementAmount" type="number"/>
        </div>
        <label class="m-0 align-self-center">{{ $t('quests.reward') }}</label>
        <div class="d-flex align-items-center gap-3">
          <b-form-select class="mt-2 mb-2" v-model="questTemplate.rewardType">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRewardType') }}
            </b-form-select-option>
            <b-form-select-option v-for="rewardType in rewardTypes" :key="rewardType" :value="rewardType">
              {{ $t(`quests.rewardType.${RewardType[rewardType]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-select class="mt-2 mb-2" v-model="questTemplate.rewardRarity">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRewardRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rewardRarity in rewardRarities" :key="rewardRarity" :value="rewardRarity">
              {{ $t(`quests.rarityType.${Rarity[rewardRarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-input v-model="questTemplate.rewardAmount" type="number"/>
        </div>
        <label class="m-0 align-self-center">{{ $t('quests.reputation') }}</label>
        <div class="d-flex align-items-center gap-3">
          <b-form-input v-model="questTemplate.reputationAmount" type="number"/>
        </div>
      </div>
      <b-button variant="primary" @click="onSubmit" :disabled="addNewQuestDisabled()">
        {{ promoQuestTemplates ? $t('quests.addNewPromoQuest') : $t('quests.addNewQuest') }}
      </b-button>
    </b-form>
    <QuestTemplatesDisplay :promoQuestTemplates="promoQuestTemplates"/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {Quest, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
import QuestTemplatesDisplay from '@/components/smart/QuestTemplatesDisplay.vue';

interface StoreMappedActions {
  addQuestTemplate(payload: { questTemplate: Quest }): Promise<void>;

  addPromoQuestTemplate(payload: { questTemplate: Quest }): Promise<void>;
}

interface Data {
  questTemplate: Quest;
  tiers: Rarity[];
  requirementTypes: RequirementType[];
  requirementRarities: Rarity[];
  rewardTypes: RewardType[];
  rewardRarities: Rarity[];
  promoQuestTemplates: boolean;
}

export default Vue.extend({

  components: {
    QuestTemplatesDisplay,
  },

  data() {
    return {
      questTemplate: {
        tier: undefined,
        requirementType: undefined,
        requirementRarity: undefined,
        requirementAmount: 0,
        rewardType: undefined,
        rewardRarity: undefined,
        rewardAmount: 0,
        reputationAmount: 0,
      },
      tiers: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      requirementTypes: [RequirementType.NONE, RequirementType.WEAPON, RequirementType.JUNK,
        RequirementType.DUST, RequirementType.TRINKET, RequirementType.SHIELD, RequirementType.RAID],
      requirementRarities: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      rewardTypes: [RewardType.NONE, RewardType.WEAPON, RewardType.JUNK,
        RewardType.DUST, RewardType.TRINKET, RewardType.SHIELD],
      rewardRarities: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      promoQuestTemplates: false,
      RequirementType,
      RewardType,
      Rarity,
    } as Data;
  },

  methods: {
    ...mapActions(['addQuestTemplate', 'addPromoQuestTemplate']) as StoreMappedActions,

    async onSubmit() {
      if (this.promoQuestTemplates) {
        await this.addPromoQuestTemplate({questTemplate: this.questTemplate});
      } else {
        await this.addQuestTemplate({questTemplate: this.questTemplate});
      }
      this.refreshQuestTemplates();
    },

    refreshQuestTemplates() {
      this.$root.$emit('refresh-quest-templates');
    },

    addNewQuestDisabled() {
      return this.questTemplate.tier === undefined
        || this.questTemplate.requirementType === undefined || this.questTemplate.requirementRarity === undefined || !this.questTemplate.requirementAmount
        || this.questTemplate.rewardType === undefined || this.questTemplate.rewardRarity === undefined || !this.questTemplate.rewardAmount
        || !this.questTemplate.reputationAmount;
    },
  },

  mounted() {
    this.refreshQuestTemplates();
  }

});
</script>

<style scoped>
.gap-3 {
  gap: 1rem;
}

.grid-container {
  display: grid;
  grid-template-columns: auto auto;
  padding: 10px;
}
</style>
