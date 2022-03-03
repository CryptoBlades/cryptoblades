<template>
  <div class="quest-character-display position-relative">
    <div v-if="character.status !== undefined && (character.status !== NftStatus.AVAILABLE)"
         class="d-flex justify-content-center align-items-center position-absolute w-100">
      <span class="busy-banner">{{ $t(`quests.nftStatus.${getNftStatus}`) }}</span>
    </div>
    <img class="quest-character-portrait m-4"
         :class="'character-animation-applied-' + getCharacterCosmetic(character.id)"
         :src="getCharacterArt(character)" alt="Character image"/>
    <div class="d-flex flex-column flex-1 mr-5">
      <span class="text-uppercase gold-text">{{ getCleanCharacterName(character.id) }}</span>
      <span class="gray-text">{{ $t(`quests.tier`) }}: <span class="gold-text">{{
          $t(`quests.reputationTier.${ReputationTier[getReputationLevel(quest.reputation)]}`)
        }}  <b-icon-question-circle
          class="pointer"
          @click="showReputationInfoModal"/></span></span>
      <span class="gray-text">{{ $t('quests.reputationPoints') }}: <span class="gold-text">{{
          quest.reputation.toLocaleString()
        }}</span></span>
      <span class="gray-text">{{ $t('quests.nextReputationTierOn') }}: <span
        class="gold-text">{{ getReputationBreakpoint(quest.reputation).toLocaleString() }}</span></span>
      <div class="quest-progress">
        <div class="quest-progress-bar" role="progressbar"
             :style="`width: calc(${quest.reputation/getReputationBreakpoint(quest.reputation)*100}% - 8px);`"
             :aria-valuenow="quest.reputation"
             aria-valuemin="0" :aria-valuemax="getReputationBreakpoint(quest.reputation)">
        </div>
        <span class="quest-progress-value">{{
            `${quest.reputation.toLocaleString()} / ${getReputationBreakpoint(quest.reputation).toLocaleString()}`
          }}</span>
      </div>
    </div>
    <b-modal v-model="showReputationModal" ok-only class="centered-modal" :title="$t('quests.reputation')">
      <div v-if="!isReputationInfoLoading" class="d-flex flex-column gap-3">
        <div class="d-flex justify-content-between">
          <span class="invisible" style="width: 15%"/>
          <div>{{ $t('quests.rarityType.COMMON') }}</div>
          <div>{{ $t('quests.rarityType.UNCOMMON') }}</div>
          <div>{{ $t('quests.rarityType.RARE') }}</div>
          <div>{{ $t('quests.rarityType.EPIC') }}</div>
          <div>{{ $t('quests.rarityType.LEGENDARY') }}</div>
        </div>
        <div v-for="(tierChance, index) in tierChances" class="d-flex justify-content-between align-items-center"
             :key="index">
          <span class="text-nowrap" style="width: 10%">{{ $t(`quests.reputationTier.${ReputationTier[index]}`) }}</span>
          <div>
            <span>{{ tierChance.common }}%</span>
          </div>
          <div>
            <span>{{ tierChance.uncommon }}%</span>
          </div>
          <div>
            <span>{{ tierChance.rare }}%</span>
          </div>
          <div>
            <span>{{ tierChance.epic }}%</span>
          </div>
          <div>
            <span>{{ tierChance.legendary }}%</span>
          </div>
        </div>
      </div>
      <span v-else>
        <i class="fas fa-spinner fa-spin"/>
        {{ $t('quests.loading') }}
      </span>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {PropType} from 'vue/types/options';
import {Rarity, RewardType} from '@/views/Quests.vue';
import {Nft, NftStatus} from '../../interfaces/Nft';
import {getCharacterArt} from '@/character-arts-placeholder';
import {mapActions, mapGetters} from 'vuex';
import {getCleanName} from '@/rename-censor';
import {Quest, ReputationLevelRequirements, ReputationTier, TierChances} from '../../views/Quests.vue';

interface StoreMappedActions {
  getQuestTierChances(payload: { tier: number }): Promise<TierChances>;
}

interface Data {
  tierChances: TierChances[];
  showReputationModal: boolean;
  isReputationInfoLoading: boolean;
}

export default Vue.extend({
  props: {
    character: {
      type: Object as PropType<Nft>,
      required: true,
    },
    quest: {
      type: Object as PropType<Quest>,
      required: true,
    },
    reputationLevelRequirements: {
      type: Object as PropType<ReputationLevelRequirements>,
    }
  },

  data() {
    return {
      tierChances: [] as TierChances[],
      showReputationModal: false,
      isReputationInfoLoading: false,
      RewardType,
      Rarity,
      ReputationTier,
      NftStatus,
    } as Data;
  },

  computed: {
    ...mapGetters([
      'getCharacterCosmetic',
      'getCharacterName',
    ]),

    getNftStatus(): string {
      if (this.character.status !== undefined && this.character.status in NftStatus) {
        return NftStatus[this.character.status];
      } else {
        return 'BUSY';
      }
    },

  },

  methods: {
    ...mapActions([
      'getQuestTierChances',
    ]) as StoreMappedActions,
    getCharacterArt,

    getCleanCharacterName(id: number) {
      return getCleanName(this.getCharacterName(id));
    },

    getReputationLevel(reputation: number) {
      if (!this.reputationLevelRequirements) return;
      if (reputation < this.reputationLevelRequirements.level2) {
        return ReputationTier.PEASANT;
      } else if (reputation < this.reputationLevelRequirements.level3) {
        return ReputationTier.TRADESMAN;
      } else if (reputation < this.reputationLevelRequirements.level4) {
        return ReputationTier.NOBLE;
      } else if (reputation < this.reputationLevelRequirements.level5) {
        return ReputationTier.KNIGHT;
      } else {
        return ReputationTier.KING;
      }
    },

    getReputationBreakpoint(reputation: number) {
      if (!this.reputationLevelRequirements) return;
      if (reputation < this.reputationLevelRequirements.level2) {
        return this.reputationLevelRequirements.level2;
      } else if (reputation < this.reputationLevelRequirements.level3) {
        return this.reputationLevelRequirements.level3;
      } else if (reputation < this.reputationLevelRequirements.level4) {
        return this.reputationLevelRequirements.level4;
      } else if (reputation < this.reputationLevelRequirements.level5) {
        return this.reputationLevelRequirements.level5;
      } else {
        return 0;
      }
    },

    async showReputationInfoModal() {
      try {
        this.showReputationModal = true;
        this.isReputationInfoLoading = true;
        this.tierChances[0] = await this.getQuestTierChances({tier: 0});
        this.tierChances[1] = await this.getQuestTierChances({tier: 1});
        this.tierChances[2] = await this.getQuestTierChances({tier: 2});
        this.tierChances[3] = await this.getQuestTierChances({tier: 3});
        this.tierChances[4] = await this.getQuestTierChances({tier: 4});
      } finally {
        this.isReputationInfoLoading = false;
      }
    },
  }


});
</script>

<style scoped>
@import '../../styles/character-cosmetics.css';

.quest-character-display {
  border-right: 1px solid #60583E;
  display: flex;
  align-items: center;
}

.quest-character-portrait {
  width: 93px;
  height: 133px;
}

.gold-text {
  color: #DABE75;
}

.gray-text {
  color: #B4B0A7;
}

.quest-progress {
  background: #070707;
  border: 1px solid #403A2C;
  display: flex;
  align-items: center;
  position: relative;
}

.quest-progress .quest-progress-bar {
  background: #DABE75;
  height: 11px;
  margin: 4px;
}

.quest-progress-value {
  text-align: center;
  font: normal normal normal 10px/11px Arial;
  color: #FFFFFF;
  position: absolute;
  width: 100%;
  font-weight: bold;
}

.busy-banner {
  text-transform: uppercase;
  transform: rotate(15deg);
  font-size: 30px;
  font-weight: bold;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
}

@media (max-width: 576px) {
  .quest-character-display {
    flex-direction: column;
    border: none;
  }
}
</style>
