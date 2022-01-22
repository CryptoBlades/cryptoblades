<template>
  <div class="quest-details d-flex flex-column justify-content-between">
    <div v-if="quest" class="d-flex h-100">
      <div class="quest-info d-flex flex-column justify-content-center">
        <div class="quest-description">
          <span
            class="font-weight-bold">{{ $t(`quests.rarityType.${Rarity[quest.tier]}`) }} {{ $t('quests.quest').toLowerCase() }}</span>
          <span>{{
              quest.requirementType === RequirementType.RAID ? $t('quests.do') : $t('quests.burn')
            }} {{ quest.requirementAmount }}x {{
              Array(quest.requirementRarity + 1).fill('★').join('')
            }} {{ $t(`quests.requirementType.${RequirementType[quest.requirementType]}`) }}</span>
        </div>
        <div class="d-flex justify-content-center p-3">
          <nft-icon v-if="quest.requirementType === RequirementType.WEAPON" :isDefault="true" :nft="{ type: 'weapon' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon v-else-if="quest.requirementType === RequirementType.JUNK" :isDefault="true" :nft="{ type: 'junk' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon v-else-if="quest.requirementType === RequirementType.TRINKET" :isDefault="true"
                    :nft="{ type: 'trinket' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon v-else-if="quest.requirementType === RequirementType.SHIELD" :isDefault="true"
                    :nft="{ type: 'shield' }"
                    :stars="quest.requirementRarity + 1"/>
          <nft-icon
            v-else-if="quest.requirementType === RequirementType.DUST && quest.requirementRarity === Rarity.COMMON"
            :isDefault="true" :nft="{ type: 'lbdust' }"/>
          <nft-icon
            v-else-if="quest.requirementType === RequirementType.DUST && quest.requirementRarity === Rarity.UNCOMMON"
            :isDefault="true" :nft="{ type: '4bdust' }"/>
          <nft-icon
            v-else-if="quest.requirementType === RequirementType.DUST && quest.requirementRarity === Rarity.RARE"
            :isDefault="true" :nft="{ type: '5bdust' }"/>
        </div>
        <div v-if="!isQuestTemplate" class="quest-progress">
          <strong class="quest-progress-text">{{ quest.progress }} / {{ quest.requirementAmount }}</strong>
          <b-progress class="reputation-progress" :max="quest.requirementAmount" :value="quest.progress"
                      variant="primary"/>
        </div>
      </div>
      <div class="reward-info d-flex flex-column justify-content-center">
        <div class="quest-description">
          <span class="font-weight-bold">{{ $t('quests.reward') }}</span>
          <span>{{ quest.reputationAmount }} {{ $t('quests.reputation') }}</span>
          <span>{{ quest.rewardAmount }}x <span>{{
              Array(quest.rewardRarity + 1).fill('★').join('')
            }}</span> {{ $t(`quests.rewardType.${RewardType[quest.rewardType]}`) }}</span>
        </div>
        <div class="d-flex justify-content-center p-3">
          <nft-icon v-if="quest.rewardType === RewardType.WEAPON" :isDefault="true" :nft="{ type: 'weapon' }"
                    :stars="quest.rewardRarity + 1"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.JUNK" :isDefault="true" :nft="{ type: 'junk' }"
                    :stars="quest.rewardRarity + 1"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.TRINKET" :isDefault="true" :nft="{ type: 'trinket' }"
                    :stars="quest.rewardRarity + 1"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.SHIELD" :isDefault="true" :nft="{ type: 'shield' }"
                    :stars="quest.rewardRarity + 1"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.COMMON"
                    :isDefault="true" :nft="{ type: 'lbdust' }"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.UNCOMMON"
                    :isDefault="true" :nft="{ type: '4bdust' }"/>
          <nft-icon v-else-if="quest.rewardType === RewardType.DUST && quest.rewardRarity === Rarity.RARE"
                    :isDefault="true" :nft="{ type: '5bdust' }"/>
        </div>
      </div>
    </div>
    <div v-if="!isQuestTemplate" class="d-flex">
      <b-button variant="primary" class="flex-1" :disabled="quest.requirementType === RequirementType.RAID"
                @click="submit">
        <!--      || questCanBeCompleted-->
        {{ $t('quests.submit') }}
      </b-button>
      <b-button v-if="questCanBeCompleted" variant="primary" class="flex-1" @click="complete">
        {{ $t('quests.complete') }}
      </b-button>
      <b-button v-else variant="primary" class="flex-1" @click="skip">
        {{ $t('quests.skip') }}
      </b-button>
    </div>
    <div v-else-if="isQuestTemplate" class="d-flex">
      <b-button variant="primary" class="flex-1" @click="deleteQuestTemplate">
        {{ $t('quests.deleteQuest') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {PropType} from 'vue/types/options';
import {Quest, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
import NftIcon from '@/components/NftIcon.vue';
import Events from '@/events';

interface StoreMappedActions {
  skipQuest(payload: { characterID: string | number }): Promise<void>;

  completeQuest(payload: { characterID: string | number }): Promise<void>;

  deleteQuest(payload: { tier: number, index: number }): Promise<void>;
}

interface Data {
  questCanBeCompleted: boolean;
}

export default Vue.extend({
  components: {NftIcon},

  props: {
    quest: {
      type: Object as PropType<Quest>,
    },
    isQuestTemplate: {
      type: Boolean,
      default: false,
    },
    questIndex: {
      type: Number,
    },
    refreshQuestTemplates: {
      type: Function,
    },
    characterId: {
      type: Number,
    }
  },

  data() {
    return {
      questCanBeCompleted: false,
      RequirementType,
      RewardType,
      Rarity,
    } as Data;
  },


  computed: {},

  methods: {
    ...mapActions(['skipQuest', 'completeQuest', 'deleteQuest']) as StoreMappedActions,

    async skip() {
      await this.skipQuest({characterID: this.characterId});
      Events.$emit('refresh-quest-data');
    },

    async complete() {
      await this.completeQuest({characterID: this.characterId});
      Events.$emit('refresh-quest-data');
    },

    async deleteQuestTemplate() {
      if (this.quest.tier !== undefined) {
        await this.deleteQuest({tier: this.quest.tier, index: this.questIndex});
        this.refreshQuestTemplates();
      }
    },

    submit() {
      this.$root.$emit('quest-submission-modal', this.quest, this.characterId, this.quest.progress);
    }
  },

  async mounted() {
    if (this.quest.progress) {
      this.questCanBeCompleted = this.quest.progress >= this.quest.requirementAmount;
    }
  }

});
</script>

<style scoped>
.quest-info {
  border-right: 1px solid;
}

.flex-1,
.quest-info,
.reward-info {
  flex: 1;
}

.quest-progress {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.reputation-progress {
  width: 75%;
}

.quest-progress-text {

}

.quest-details {
  border: 1px solid;
  border-radius: 5px;
  width: 25rem;
  height: auto;
}

.quest-description {
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
