<template>
  <div class="p-1">
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
            <b-form-select-option v-for="rarity in rarities" :key="rarity" :value="rarity">
              {{ $t(`quests.rarityType.${Rarity[rarity]}`) }}
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
          <b-form-select v-if="questTemplate.requirementType === RequirementType.DUST" class="mt-2 mb-2"
                         v-model="questTemplate.requirementRarity"
                         :disabled="questTemplate.requirementType === undefined">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRequirementRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rarity in dustRarities" :key="rarity" :value="rarity">
              {{ $t(`quests.dustRarityType.${DustRarity[rarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-select v-else class="mt-2 mb-2" v-model="questTemplate.requirementRarity"
                         :disabled="questTemplate.requirementType === undefined">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRequirementRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rarity in rarities" :key="rarity" :value="rarity">
              {{ $t(`quests.rarityType.${Rarity[rarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-input v-model="questTemplate.requirementAmount"
                        :disabled="questTemplate.requirementRarity === undefined" type="number" number/>
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
          <b-form-select v-if="questTemplate.rewardType === RewardType.DUST" class="mt-2 mb-2"
                         v-model="questTemplate.rewardRarity"
                         :disabled="questTemplate.rewardType === undefined">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRewardRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rarity in dustRarities" :key="rarity" :value="rarity">
              {{ $t(`quests.dustRarityType.${DustRarity[rarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-select v-else class="mt-2 mb-2" v-model="questTemplate.rewardRarity"
                         :disabled="questTemplate.rewardType === undefined">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRewardRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rarity in rarities" :key="rarity" :value="rarity">
              {{ $t(`quests.rarityType.${Rarity[rarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-input v-model="questTemplate.rewardAmount" :disabled="questTemplate.rewardRarity === undefined"
                        type="number" number/>
        </div>
        <label class="m-0 align-self-center">{{ $t('quests.reputation') }}</label>
        <div class="d-flex align-items-center gap-3">
          <b-form-input v-model="questTemplate.reputationAmount" type="number" number/>
        </div>
      </div>
      <b-button variant="primary" @click="showTemplateConfirmationModal = true"
                :disabled="addNewQuestDisabled()">
        {{ promoQuestTemplates ? $t('quests.addNewPromoQuest') : $t('quests.addNewQuest') }}
      </b-button>
    </b-form>
    <b-form v-if="reputationLevelRequirements" class="d-flex flex-column gap-3">
      <h2 class="pt-3">{{ $t('quests.updateReputationLevelRequirements') }}</h2>
      <div class="requirements-grid-container gap-3">
        <label class="m-0 align-self-center">{{ $t('quests.reputationLevel', {level: 2}) }}</label>
        <b-form-input type="number" number v-model="reputationLevelRequirements.level2"/>
        <label class="m-0 align-self-center">{{ $t('quests.reputationLevel', {level: 3}) }}</label>
        <b-form-input type="number" number v-model="reputationLevelRequirements.level3"/>
        <label class="m-0 align-self-center">{{ $t('quests.reputationLevel', {level: 4}) }}</label>
        <b-form-input type="number" number v-model="reputationLevelRequirements.level4"/>
        <label class="m-0 align-self-center">{{ $t('quests.reputationLevel', {level: 5}) }}</label>
        <b-form-input type="number" number v-model="reputationLevelRequirements.level5"/>
      </div>
      <b-button variant="primary" @click="updateRequirements" :disabled="updateRequirementsDisabled()">
        {{ $t('quests.updateRequirements') }}
      </b-button>
    </b-form>
    <b-form class="d-flex flex-column gap-3">
      <h2 class="pt-3">{{ $t('quests.updateSkipQuestStaminaCost') }}</h2>
      <div class="requirements-grid-container gap-3">
        <label class="m-0 align-self-center">{{ $t('quests.staminaCost') }}</label>
        <b-form-input type="number" number v-model="staminaCost"/>
      </div>
      <b-button variant="primary" @click="updateStaminaCost" :disabled="isLoading || showTemplateConfirmationModal">
        {{ $t('quests.updateStaminaCost') }}
      </b-button>
    </b-form>
    <QuestTemplatesDisplay :promoQuestTemplates="promoQuestTemplates"/>
    <b-modal v-model="showTemplateConfirmationModal" @ok.prevent="onSubmit" :ok-disabled="isLoading"
             :title="promoQuestTemplates ? $t('quests.addNewPromoQuest') : $t('quests.addNewQuest')">
      <div class="d-flex flex-column align-items-center">
        <h4 class="text-center">
          {{ promoQuestTemplates ? $t('quests.areYouSureAddPromoQuest') : $t('quests.areYouSureAddQuest') }}
        </h4>
        <QuestDetails :quest="questTemplate" :isDisplayOnly="true"/>
      </div>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {
  DustRarity,
  Quest,
  Rarity,
  ReputationLevelRequirements,
  RequirementType,
  RewardType,
  VAR_REPUTATION_LEVEL_2,
  VAR_REPUTATION_LEVEL_3,
  VAR_REPUTATION_LEVEL_4,
  VAR_REPUTATION_LEVEL_5
} from '@/views/Quests.vue';
import QuestTemplatesDisplay from '@/components/smart/QuestTemplatesDisplay.vue';
import QuestDetails from '@/components/smart/QuestDetails.vue';

interface StoreMappedActions {
  addQuestTemplate(payload: { questTemplate: Quest }): Promise<void>;

  addPromoQuestTemplate(payload: { questTemplate: Quest }): Promise<void>;

  getReputationLevelRequirements(payload: { reputationLevels: number[] }): Promise<ReputationLevelRequirements>;

  setReputationLevelRequirements(payload: { reputationLevels: number[], requirements: number[] }): Promise<void>;

  setSkipQuestStaminaCost(payload: { staminaCost: number }): Promise<void>;

  getSkipQuestStaminaCost(): Promise<number>;
}

interface Data {
  questTemplate: Quest;
  rarities: Rarity[];
  dustRarities: DustRarity[];
  requirementTypes: RequirementType[];
  rewardTypes: RewardType[];
  promoQuestTemplates: boolean;
  isLoading: boolean;
  showTemplateConfirmationModal: boolean;
  reputationLevelRequirements?: ReputationLevelRequirements;
  staminaCost: number;
}

export default Vue.extend({

  components: {QuestTemplatesDisplay, QuestDetails},

  data() {
    return {
      questTemplate: {
        progress: 0,
        reputation: 0,
        id: 0,
        requirementAmount: 0,
        rewardAmount: 0,
        reputationAmount: 0,
      },
      rarities: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      dustRarities: [DustRarity.LESSER, DustRarity.GREATER, DustRarity.POWERFUL],
      requirementTypes: [RequirementType.NONE, RequirementType.WEAPON, RequirementType.JUNK,
        RequirementType.DUST, RequirementType.TRINKET, RequirementType.SHIELD, RequirementType.RAID],
      rewardTypes: [RewardType.NONE, RewardType.WEAPON, RewardType.JUNK,
        RewardType.DUST, RewardType.TRINKET, RewardType.SHIELD],
      promoQuestTemplates: false,
      isLoading: false,
      showTemplateConfirmationModal: false,
      reputationLevelRequirements: undefined,
      staminaCost: 0,
      RequirementType,
      RewardType,
      Rarity,
      DustRarity,
    } as Data;
  },

  methods: {
    ...mapActions([
      'addQuestTemplate',
      'addPromoQuestTemplate',
      'getReputationLevelRequirements',
      'setReputationLevelRequirements',
      'setSkipQuestStaminaCost',
      'getSkipQuestStaminaCost',
    ]) as StoreMappedActions,

    async onSubmit() {
      try {
        this.isLoading = true;
        if (this.promoQuestTemplates) {
          await this.addPromoQuestTemplate({questTemplate: this.questTemplate});
        } else {
          await this.addQuestTemplate({questTemplate: this.questTemplate});
        }
        this.refreshQuestTemplates();
      } finally {
        this.isLoading = false;
        this.showTemplateConfirmationModal = false;
      }
    },

    async updateRequirements() {
      if (!this.reputationLevelRequirements) return;
      try {
        this.isLoading = true;
        await this.setReputationLevelRequirements({
          reputationLevels: [VAR_REPUTATION_LEVEL_2, VAR_REPUTATION_LEVEL_3, VAR_REPUTATION_LEVEL_4, VAR_REPUTATION_LEVEL_5],
          requirements: [this.reputationLevelRequirements.level2, this.reputationLevelRequirements.level3,
            this.reputationLevelRequirements.level4, this.reputationLevelRequirements.level5]
        });
      } finally {
        this.isLoading = false;
      }
    },

    async updateStaminaCost() {
      if (!this.staminaCost) return;
      try {
        this.isLoading = true;
        await this.setSkipQuestStaminaCost({staminaCost: this.staminaCost});
        this.staminaCost = await this.getSkipQuestStaminaCost();
      } finally {
        this.isLoading = false;
      }
    },

    refreshQuestTemplates() {
      this.$root.$emit('refresh-quest-templates');
    },

    addNewQuestDisabled() {
      return this.questTemplate.tier === undefined
        || this.questTemplate.requirementType === undefined || this.questTemplate.requirementRarity === undefined || !this.questTemplate.requirementAmount
        || this.questTemplate.rewardType === undefined || this.questTemplate.rewardRarity === undefined || !this.questTemplate.rewardAmount
        || !this.questTemplate.reputationAmount || this.showTemplateConfirmationModal;
    },

    updateRequirementsDisabled() {
      return !this.reputationLevelRequirements ||
        !this.reputationLevelRequirements.level2 ||
        !this.reputationLevelRequirements.level3 ||
        !this.reputationLevelRequirements.level4 ||
        !this.reputationLevelRequirements.level5 ||
        this.isLoading || this.showTemplateConfirmationModal;
    }
  },

  async mounted() {
    const reputationLevels = [VAR_REPUTATION_LEVEL_2, VAR_REPUTATION_LEVEL_3, VAR_REPUTATION_LEVEL_4, VAR_REPUTATION_LEVEL_5];
    try {
      this.isLoading = true;
      this.refreshQuestTemplates();
      this.reputationLevelRequirements = await this.getReputationLevelRequirements({reputationLevels});
      this.staminaCost = await this.getSkipQuestStaminaCost();
    } finally {
      this.isLoading = false;
    }
  }

});
</script>

<style scoped>
.gap-3 {
  gap: 1rem;
}

.requirements-grid-container,
.grid-container {
  display: grid;
  grid-template-columns: 1fr 2fr;
  padding: 10px;
}

.requirements-grid-container {
  grid-template-columns: 1fr 1fr;
}
</style>
