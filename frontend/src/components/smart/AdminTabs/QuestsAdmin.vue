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
          <b-form-input v-model="questTemplate.requirementExternalAddress"
                        v-if="questTemplate.requirementType === RequirementType.EXTERNAL
                        || questTemplate.requirementType === RequirementType.EXTERNAL_HOLD"
                        :placeholder="$t('quests.ERC20/ERC721Address')"/>
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
          <b-form-select
            v-else-if="questTemplate.requirementType !== RequirementType.RAID
            && questTemplate.requirementType !== RequirementType.STAMINA
            && questTemplate.requirementType !== RequirementType.SOUL
            && questTemplate.requirementType !== RequirementType.EXTERNAL
            && questTemplate.requirementType !== RequirementType.EXTERNAL_HOLD"
            class="mt-2 mb-2"
            v-model="questTemplate.requirementRarity"
            :disabled="questTemplate.requirementType === undefined">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRequirementRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rarity in rarities" :key="rarity" :value="rarity">
              {{ $t(`quests.rarityType.${Rarity[rarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-input v-model="questTemplate.requirementAmount" :min="0" type="number" number/>
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
          <b-form-input v-model="questTemplate.rewardExternalAddress"
                        v-if="questTemplate.rewardType === RewardType.EXTERNAL"
                        :placeholder="$t('quests.ERC20/ERC721Address')"/>
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
          <b-form-select
            v-else-if="questTemplate.rewardType !== RewardType.EXPERIENCE
            && questTemplate.rewardType !== RewardType.SOUL
            && questTemplate.rewardType !== RewardType.EXTERNAL"
            class="mt-2 mb-2"
            v-model="questTemplate.rewardRarity"
            :disabled="questTemplate.rewardType === undefined">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRewardRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rarity in rarities" :key="rarity" :value="rarity">
              {{ $t(`quests.rarityType.${Rarity[rarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-input v-model="questTemplate.rewardAmount" type="number" number :min="0"/>
        </div>
        <label class="m-0 align-self-center">{{ $t('quests.reputation') }}</label>
        <div class="d-flex align-items-center gap-3">
          <b-form-input v-model="questTemplate.reputationAmount" type="number" number :min="0"/>
        </div>
        <label class="m-0 align-self-center">{{ $t('quests.limitedOptional') }}</label>
        <div class="d-flex align-items-center gap-3 mt-2">
          <b-form-input v-model="supply" type="number" number :placeholder="$t('quests.supplyOptional')" :min="0"/>
          <i id="unix-timestamp-hint" class="far fa-question-circle hint"/>
          <b-tooltip target="unix-timestamp-hint">
            {{ $t('quests.unixTimestampHint') }} <a href="https://www.unixtimestamp.com/" target="_blank">https://www.unixtimestamp.com/</a>
          </b-tooltip>
          <b-form-input v-model="timestamp" type="number" number :placeholder="$t('quests.timestampOptional')"
                        :min="0"/>
        </div>
      </div>
      <b-button variant="primary" @click="showConfirmationModal"
                :disabled="addNewQuestDisabled()">
        {{ promoQuestTemplates ? $t('quests.addNewPromoQuest') : $t('quests.addNewQuest') }}
      </b-button>
    </b-form>
    <QuestTemplatesDisplay :promoQuestTemplates="promoQuestTemplates"/>
    <h2>{{ $t('quests.createNewWeeklyReward') }}</h2>
    <b-form class="d-flex flex-column gap-3">
      <div class="grid-container">
        <label class="m-0 align-self-center">{{ $t('quests.reward') }}</label>
        <div class="d-flex align-items-center gap-3">
          <b-form-select class="mt-2 mb-2" v-model="weeklyReward.rewardType">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRewardType') }}
            </b-form-select-option>
            <b-form-select-option v-for="rewardType in weeklyRewardTypes" :key="rewardType" :value="rewardType">
              {{ $t(`quests.rewardType.${RewardType[rewardType]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-input v-model="weeklyReward.rewardExternalAddress"
                        v-if="weeklyReward.rewardType === RewardType.EXTERNAL"
                        :placeholder="$t('quests.ERC20/ERC721Address')"/>
          <b-form-select v-if="weeklyReward.rewardType === RewardType.DUST" class="mt-2 mb-2"
                         v-model="weeklyReward.rewardRarity"
                         :disabled="weeklyReward.rewardType === undefined">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRewardRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rarity in dustRarities" :key="rarity" :value="rarity">
              {{ $t(`quests.dustRarityType.${DustRarity[rarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-select
            v-else-if="weeklyReward.rewardType !== RewardType.EXPERIENCE
            && weeklyReward.rewardType !== RewardType.SOUL
            && weeklyReward.rewardType !== RewardType.EXTERNAL"
            class="mt-2 mb-2"
            v-model="weeklyReward.rewardRarity"
            :disabled="weeklyReward.rewardType === undefined">
            <b-form-select-option :value="undefined" disabled>
              {{ $t('quests.pleaseSelectRewardRarity') }}
            </b-form-select-option>
            <b-form-select-option v-for="rarity in rarities" :key="rarity" :value="rarity">
              {{ $t(`quests.rarityType.${Rarity[rarity]}`) }}
            </b-form-select-option>
          </b-form-select>
          <b-form-input v-model="weeklyReward.rewardAmount" type="number" number :min="0"/>
        </div>
        <label class="m-0 align-self-center">{{ $t('quests.reputation') }}</label>
        <div class="d-flex align-items-center gap-3">
          <b-form-input v-model="weeklyReward.reputationAmount" type="number" number :min="0"/>
        </div>
      </div>
      <b-button variant="primary" @click="addReward"
                :disabled="addNewWeeklyRewardDisabled()">
        {{ $t('quests.addNewWeeklyReward') }}
      </b-button>
      <span v-if="addedWeeklyRewardId">{{ $t('quests.addedWeeklyRewardID') }}: {{ addedWeeklyRewardId }}</span>
    </b-form>
    <h2 class="mt-2">{{ $t('quests.setWeeklyReward') }}</h2>
    <b-form class="d-flex flex-column gap-3">
      <div class="d-flex align-items-center gap-3 mt-2">
        <b-form-input v-model="rewardID" type="number" number :placeholder="$t('quests.rewardID')" :min="0"/>
        <i id="unix-timestamp-hint2" class="far fa-question-circle hint"/>
        <b-tooltip target="unix-timestamp-hint2">
          {{ $t('quests.unixTimestampHint') }} <a href="https://www.unixtimestamp.com/" target="_blank">https://www.unixtimestamp.com/</a>
        </b-tooltip>
        <b-form-input v-model="week" type="number" number :placeholder="$t('quests.timestamp')" :min="0"/>
      </div>
      <b-button variant="primary" @click="setReward">
        {{ $t('quests.setWeeklyReward') }}
      </b-button>
    </b-form>
    <b-form v-if="reputationLevelRequirements" class="d-flex flex-column gap-3">
      <h2 class="pt-3">{{ $t('quests.updateReputationLevelRequirements') }}</h2>
      <div class="requirements-grid-container gap-3">
        <label class="m-0 align-self-center">{{ $t('quests.reputationLevel', {level: 2}) }}</label>
        <b-form-input type="number" number :min="0" v-model="reputationLevelRequirements.level2"/>
        <label class="m-0 align-self-center">{{ $t('quests.reputationLevel', {level: 3}) }}</label>
        <b-form-input type="number" number :min="0" v-model="reputationLevelRequirements.level3"/>
        <label class="m-0 align-self-center">{{ $t('quests.reputationLevel', {level: 4}) }}</label>
        <b-form-input type="number" number :min="0" v-model="reputationLevelRequirements.level4"/>
        <label class="m-0 align-self-center">{{ $t('quests.reputationLevel', {level: 5}) }}</label>
        <b-form-input type="number" number :min="0" v-model="reputationLevelRequirements.level5"/>
      </div>
      <b-button variant="primary" @click="updateRequirements" :disabled="updateRequirementsDisabled()">
        {{ $t('quests.updateRequirements') }}
      </b-button>
    </b-form>
    <b-form class="d-flex flex-column gap-3">
      <h2 class="pt-3">{{ $t('quests.updateSkipQuestStaminaCost') }}</h2>
      <div class="requirements-grid-container gap-3">
        <label class="m-0 align-self-center">{{ $t('quests.staminaCost') }}</label>
        <b-form-input type="number" number :min="0" v-model="staminaCost"/>
      </div>
      <b-button variant="primary" @click="updateStaminaCost"
                :disabled="isLoading || showTemplateConfirmationModal || showPromoToggleConfirmationModal">
        {{ $t('quests.updateStaminaCost') }}
      </b-button>
    </b-form>
    <b-form class="d-flex flex-column gap-3">
      <h2 class="pt-3">{{ $t('quests.updateWeeklyQuestsCompletionsLimit') }}</h2>
      <div class="requirements-grid-container gap-3">
        <label class="m-0 align-self-center">{{ $t('quests.weeklyCompletionsLimit') }}</label>
        <b-form-input type="number" number :min="0" v-model="weeklyCompletionsLimit"/>
      </div>
      <b-button variant="primary" @click="updateWeeklyCompletionsLimit"
                :disabled="isLoading || showTemplateConfirmationModal || showPromoToggleConfirmationModal">
        {{ $t('quests.updateWeeklyCompletionsLimit') }}
      </b-button>
    </b-form>
    <b-form class="d-flex flex-column gap-3">
      <h2 class="pt-3">{{ $t('quests.updateUsePromoQuestTemplates') }}</h2>
      <div class="requirements-grid-container gap-3">
        <label class="m-0 align-self-center">{{ $t('quests.usePromoQuestTemplates') }}</label>
        <span v-if="!isLoading" class="font-weight-bold">{{ usePromoQuests }}</span>
        <span v-else>
          <i class="fas fa-spinner fa-spin"/>
          {{ $t('quests.loading') }}
        </span>
      </div>
      <b-button variant="primary" @click="showPromoToggleConfirmationModal = true"
                :disabled="isLoading || showTemplateConfirmationModal || showPromoToggleConfirmationModal">
        {{ $t('quests.togglePromoQuestsUsage') }}
      </b-button>
    </b-form>
    <b-form class="d-flex flex-column gap-3">
      <h2 class="pt-3">{{ $t('quests.tierChances') }}</h2>
      <div v-if="tierChances.length !== 0" class="d-flex flex-column gap-3">
        <div class="d-flex justify-content-between">
          <span class="invisible">{{ $t('quests.level', {level: 0}) }}</span>
          <div>{{ $t('quests.rarityType.COMMON') }}</div>
          <div>{{ $t('quests.rarityType.UNCOMMON') }}</div>
          <div>{{ $t('quests.rarityType.RARE') }}</div>
          <div>{{ $t('quests.rarityType.EPIC') }}</div>
          <div>{{ $t('quests.rarityType.LEGENDARY') }}</div>
          <div class="invisible">
            <b-button variant="primary">{{ $t('quests.updateStaminaCost') }}</b-button>
          </div>
        </div>
        <div v-for="(tierChance, index) in tierChances" class="d-flex justify-content-between align-items-center"
             :key="index">
          <span class="text-nowrap">{{ $t('quests.level', {level: index + 1}) }}</span>
          <div>
            <b-form-input type="number" number :min="0" :value="tierChance.common" readonly/>
          </div>
          <div>
            <b-form-input type="number" @change="() => updateCommonChance(index)" number :min="0"
                          v-model="tierChance.uncommon"/>
          </div>
          <div>
            <b-form-input type="number" @change="() => updateCommonChance(index)" number :min="0"
                          v-model="tierChance.rare"/>
          </div>
          <div>
            <b-form-input type="number" @change="() => updateCommonChance(index)" number :min="0"
                          v-model="tierChance.epic"/>
          </div>
          <div>
            <b-form-input type="number" @change="() => updateCommonChance(index)" number :min="0"
                          v-model="tierChance.legendary"/>
          </div>
          <b-button variant="primary" @click="() => updateTierChances(index, tierChance)" :disabled="isLoading">
            {{ $t('quests.updateForLevel', {level: index + 1}) }}
          </b-button>
        </div>
      </div>
      <h3 v-else>
        <i class="fas fa-spinner fa-spin"/>
        {{ $t('quests.loading') }}
      </h3>
    </b-form>
    <b-modal v-model="showTemplateConfirmationModal" @ok.prevent="onSubmit" :ok-disabled="isLoading"
             :title="promoQuestTemplates ? $t('quests.addNewPromoQuest') : $t('quests.addNewQuest')">
      <div class="d-flex flex-column align-items-center">
        <h4 class="text-center">
          {{ promoQuestTemplates ? $t('quests.areYouSureAddPromoQuest') : $t('quests.areYouSureAddQuest') }}
        </h4>
        <QuestTemplate :quest="questTemplate" :deadline="timestamp" :supply="supply" isDisplayOnly/>
      </div>
    </b-modal>
    <b-modal v-model="showPromoToggleConfirmationModal" @ok.prevent="togglePromoQuests" :ok-disabled="isLoading"
             :title="$t('quests.togglePromoQuestsUsage')">
      <div class="d-flex flex-column align-items-center">
        <h4 class="text-center">
          {{ usePromoQuests ? $t('quests.addNewTurnOffPromoQuestsUsage') : $t('quests.addNewTurnOnPromoQuestsUsage') }}
        </h4>
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
  QuestItemType,
  Rarity,
  ReputationLevelRequirements,
  RequirementType,
  RewardType,
  TierChances
} from '../../../views/Quests.vue';
import QuestTemplatesDisplay from '../QuestTemplatesDisplay.vue';
import QuestTemplate from '../QuestTemplate.vue';
import {isValidWeb3Address} from '../../../utils/common';

interface StoreMappedActions {
  addQuestTemplate(payload: { questTemplate: Quest, isPromo: boolean, supply: number, deadline: number }): Promise<void>;

  addPromoQuestTemplate(payload: { questTemplate: Quest }): Promise<void>;

  getReputationLevelRequirements(): Promise<ReputationLevelRequirements>;

  setReputationLevelRequirements(payload: { requirements: number[] }): Promise<void>;

  setSkipQuestStaminaCost(payload: { staminaCost: number }): Promise<void>;

  getSkipQuestStaminaCost(): Promise<number>;

  setWeeklyCompletionsLimit(payload: { newLimit: number }): Promise<void>;

  getWeeklyCompletionsLimit(): Promise<number>;

  getQuestTierChances(payload: { tier: number }): Promise<TierChances>;

  setQuestTierChances(payload: { tier: number, tierChances: TierChances }): Promise<void>;

  isUsingPromoQuests(): Promise<boolean>;

  toggleUsePromoQuests(): Promise<void>;

  addWeeklyReward(payload: { weeklyReward: WeeklyReward }): Promise<number>;

  setWeeklyReward(payload: { rewardID: number, timestamp: number }): Promise<void>;
}

interface WeeklyReward {
  rewardType?: QuestItemType;
  rewardRarity?: Rarity;
  rewardAmount?: number;
  rewardExternalAddress: string;
  reputationAmount?: number;
  timestamp?: number;
}

interface Data {
  questTemplate: Quest;
  weeklyReward: WeeklyReward;
  rarities: Rarity[];
  dustRarities: DustRarity[];
  requirementTypes: RequirementType[];
  rewardTypes: RewardType[];
  weeklyRewardTypes: RewardType[];
  promoQuestTemplates: boolean;
  isLoading: boolean;
  showTemplateConfirmationModal: boolean;
  showPromoToggleConfirmationModal: boolean;
  reputationLevelRequirements?: ReputationLevelRequirements;
  staminaCost: number;
  weeklyCompletionsLimit: number;
  tierChances: TierChances[];
  usePromoQuests: boolean;
  supply?: number;
  timestamp?: number;
}

export default Vue.extend({

  components: {QuestTemplatesDisplay, QuestTemplate},

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
      weeklyReward: {
        rewardType: undefined,
        rewardRarity: undefined,
        rewardAmount: 0,
        rewardExternalAddress: '',
        reputationAmount: 0,
      },
      addedWeeklyRewardId: undefined,
      week: undefined,
      rewardID: undefined,
      rarities: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      dustRarities: [DustRarity.LESSER, DustRarity.GREATER, DustRarity.POWERFUL],
      requirementTypes: [RequirementType.WEAPON, RequirementType.JUNK,
        RequirementType.DUST, RequirementType.TRINKET,
        RequirementType.SHIELD, RequirementType.STAMINA,
        RequirementType.SOUL, RequirementType.RAID,
        RequirementType.EXTERNAL, RequirementType.EXTERNAL_HOLD],
      rewardTypes: [RewardType.WEAPON, RewardType.JUNK,
        RewardType.DUST, RewardType.TRINKET,
        RewardType.SHIELD, RewardType.EXPERIENCE,
        RewardType.SOUL, RewardType.EXTERNAL],
      weeklyRewardTypes: [RewardType.WEAPON, RewardType.JUNK,
        RewardType.DUST, RewardType.TRINKET,
        RewardType.SHIELD, RewardType.SOUL,
        RewardType.EXTERNAL],
      promoQuestTemplates: false,
      isLoading: false,
      showTemplateConfirmationModal: false,
      showPromoToggleConfirmationModal: false,
      reputationLevelRequirements: undefined,
      staminaCost: 0,
      weeklyCompletionsLimit: 0,
      tierChances: [] as TierChances[],
      usePromoQuests: false,
      supply: undefined,
      timestamp: undefined,
      RequirementType,
      RewardType,
      Rarity,
      DustRarity,
    } as Data;
  },

  methods: {
    ...mapActions([
      'addQuestTemplate',
      'getReputationLevelRequirements',
      'setReputationLevelRequirements',
      'setSkipQuestStaminaCost',
      'getSkipQuestStaminaCost',
      'getWeeklyCompletionsLimit',
      'setWeeklyCompletionsLimit',
      'getQuestTierChances',
      'setQuestTierChances',
      'isUsingPromoQuests',
      'toggleUsePromoQuests',
      'addWeeklyReward',
      'setWeeklyReward',
    ]) as StoreMappedActions,

    showConfirmationModal() {
      if (this.questTemplate.requirementType === RequirementType.RAID
        || this.questTemplate.requirementType === RequirementType.STAMINA
        || this.questTemplate.requirementType === RequirementType.SOUL
        || this.questTemplate.requirementType === RequirementType.EXTERNAL
        || this.questTemplate.requirementType === RequirementType.EXTERNAL_HOLD) {
        this.questTemplate.requirementRarity = Rarity.COMMON;
      }
      if (this.questTemplate.rewardType === RewardType.EXPERIENCE
        || this.questTemplate.rewardType === RewardType.SOUL
        || this.questTemplate.rewardType === RewardType.EXTERNAL) {
        this.questTemplate.rewardRarity = Rarity.COMMON;
      }
      if (!this.questTemplate.deadline && !this.questTemplate.supply) {
        this.questTemplate.deadline = 0;
        this.questTemplate.supply = 0;
      }
      this.showTemplateConfirmationModal = true;
    },

    async addReward() {
      if (this.weeklyReward.rewardType === RewardType.SOUL
        || this.weeklyReward.rewardType === RewardType.EXTERNAL) {
        this.weeklyReward.rewardRarity = Rarity.COMMON;
      }
      try {
        this.isLoading = true;
        this.addedWeeklyRewardId = await this.addWeeklyReward({
          weeklyReward: this.weeklyReward,
        });
      } finally {
        this.isLoading = false;
      }
    },

    async setReward() {
      try {
        this.isLoading = true;
        await this.setWeeklyReward({
          rewardID: this.rewardID,
          timestamp: this.week,
        });
      } finally {
        this.isLoading = false;
      }
    },

    async onSubmit() {
      try {
        this.isLoading = true;
        await this.addQuestTemplate({
          questTemplate: this.questTemplate,
          isPromo: this.promoQuestTemplates,
          supply: this.supply ? this.supply : 0,
          deadline: this.timestamp ? this.timestamp : 0,
        });
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
          requirements: [this.reputationLevelRequirements.level2, this.reputationLevelRequirements.level3,
            this.reputationLevelRequirements.level4, this.reputationLevelRequirements.level5]
        });
      } finally {
        this.isLoading = false;
      }
    },

    async updateStaminaCost() {
      try {
        this.isLoading = true;
        await this.setSkipQuestStaminaCost({staminaCost: this.staminaCost});
        this.staminaCost = await this.getSkipQuestStaminaCost();
      } finally {
        this.isLoading = false;
      }
    },

    async updateWeeklyCompletionsLimit() {
      try {
        this.isLoading = true;
        await this.setWeeklyCompletionsLimit({newLimit: this.weeklyCompletionsLimit});
        this.weeklyCompletionsLimit = await this.getWeeklyCompletionsLimit();
      } finally {
        this.isLoading = false;
      }
    },

    async updateTierChances(tier: number, tierChances: TierChances) {
      try {
        this.isLoading = true;
        await this.setQuestTierChances({tier, tierChances});
        await this.refreshTierChance(tier);
      } finally {
        this.isLoading = false;
      }
    },

    async togglePromoQuests() {
      try {
        this.isLoading = true;
        await this.toggleUsePromoQuests();
        this.usePromoQuests = await this.isUsingPromoQuests();
      } finally {
        this.isLoading = false;
        this.showPromoToggleConfirmationModal = false;
      }
    },

    refreshQuestTemplates() {
      this.$root.$emit('refresh-quest-templates');
    },

    addNewQuestDisabled() {
      return this.questTemplate.tier === undefined
        || this.questTemplate.requirementType === undefined
        || (this.questTemplate.requirementRarity === undefined
          && this.questTemplate.requirementType !== RequirementType.RAID
          && this.questTemplate.requirementType !== RequirementType.STAMINA
          && this.questTemplate.requirementType !== RequirementType.SOUL
          && this.questTemplate.requirementType !== RequirementType.EXTERNAL
          && this.questTemplate.requirementType !== RequirementType.EXTERNAL_HOLD)
        || !this.questTemplate.requirementAmount
        || this.questTemplate.rewardType === undefined
        || (this.questTemplate.rewardRarity === undefined
          && this.questTemplate.rewardType !== RewardType.EXPERIENCE
          && this.questTemplate.rewardType !== RewardType.SOUL
          && this.questTemplate.rewardType !== RewardType.EXTERNAL)
        || !this.questTemplate.rewardAmount
        || !this.questTemplate.reputationAmount
        || (this.timestamp && !this.supply)
        || (this.supply && !this.timestamp)
        || ((this.questTemplate.requirementType === RequirementType.EXTERNAL
            || this.questTemplate.requirementType === RequirementType.EXTERNAL_HOLD)
          && !isValidWeb3Address(this.questTemplate.requirementExternalAddress))
        || (this.questTemplate.rewardType === RewardType.EXTERNAL
          && !isValidWeb3Address(this.questTemplate.rewardExternalAddress))
        || this.showTemplateConfirmationModal || this.isLoading;
    },

    addNewWeeklyRewardDisabled() {
      return this.weeklyReward.rewardType === undefined
        || (this.weeklyReward.rewardRarity === undefined
          && this.weeklyReward.rewardType !== RewardType.EXPERIENCE
          && this.weeklyReward.rewardType !== RewardType.SOUL
          && this.weeklyReward.rewardType !== RewardType.EXTERNAL)
        || !this.weeklyReward.rewardAmount
        || (this.weeklyReward.rewardType === RewardType.EXTERNAL
          && !isValidWeb3Address(this.weeklyReward.rewardExternalAddress))
        || this.showTemplateConfirmationModal || this.isLoading;
    },

    updateRequirementsDisabled() {
      return !this.reputationLevelRequirements ||
        !this.reputationLevelRequirements.level2 ||
        !this.reputationLevelRequirements.level3 ||
        !this.reputationLevelRequirements.level4 ||
        !this.reputationLevelRequirements.level5 ||
        this.isLoading || this.showTemplateConfirmationModal;
    },

    async refreshTierChance(tier: number) {
      this.tierChances[tier] = await this.getQuestTierChances({tier});
    },

    async refreshTierChances() {
      this.tierChances[0] = await this.getQuestTierChances({tier: 0});
      this.tierChances[1] = await this.getQuestTierChances({tier: 1});
      this.tierChances[2] = await this.getQuestTierChances({tier: 2});
      this.tierChances[3] = await this.getQuestTierChances({tier: 3});
      this.tierChances[4] = await this.getQuestTierChances({tier: 4});
    },

    updateCommonChance(index: number) {
      this.tierChances[index].common = 100 - this.tierChances[index].uncommon - this.tierChances[index].rare -
        this.tierChances[index].epic - this.tierChances[index].legendary;
      Vue.set(this.tierChances, index, this.tierChances[index]);
    },
  },

  async mounted() {
    try {
      this.isLoading = true;
      this.refreshQuestTemplates();
      this.reputationLevelRequirements = await this.getReputationLevelRequirements();
      this.staminaCost = await this.getSkipQuestStaminaCost();
      this.weeklyCompletionsLimit = await this.getWeeklyCompletionsLimit();
      this.usePromoQuests = await this.isUsingPromoQuests();
      await this.refreshTierChances();
    } finally {
      this.isLoading = false;
    }
  }

});
</script>

<style scoped>
.requirements-grid-container,
.grid-container {
  display: grid;
  grid-template-columns: 1fr 2fr;
  padding: 10px;
}

.requirements-grid-container {
  grid-template-columns: 1fr 1fr;
}

.invisible {
  visibility: hidden;
}
</style>
