<template>
  <div v-if="characters.length !== 0" class="d-flex flex-wrap quests-container">
    <div v-for="character in characters" :key="character.id" class="d-flex quest-row">
      <div class="character"
           :class="[showCosmetics ? 'character-animation-applied-' + getCharacterCosmetic(character.id) : undefined]">
        <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
          <slot name="above" :character="character"></slot>
        </div>
        <slot name="sold" :character="character"></slot>
        <div class="art">
          <div class="animation"/>
          <CharacterArt
            :class="[showCosmetics ? 'character-cosmetic-applied-' + getCharacterCosmetic(character.id) : undefined]"
            :character="character" :hideIdContainer="true" :hideXpBar="true"/>
        </div>
        <div
          v-if="character.quest && character.quest.reputation !== undefined && reputationLevelRequirements"
          class="xp">
          <span>{{ $t('quests.reputationLevel', {level: getReputationLevel(character.quest.reputation)}) }} <b-icon-question-circle
            class="pointer"
            @click="showReputationInfoModal"/></span>
          <strong v-if="getReputationLevel(character.quest.reputation) !== 5"
                  class="outline xp-text">{{ character.quest.reputation || 0 }} /
            {{ getReputationBreakpoint(character.quest.reputation) }}</strong>
          <b-progress v-if="getReputationLevel(character.quest.reputation) !== 5" class="reputation-progress"
                      :max="getReputationBreakpoint(character.quest.reputation)" :value="character.quest.reputation"
                      variant="primary"/>
        </div>
      </div>
      <QuestDetails v-if="character.quest && character.quest.id !== 0" :quest="character.quest"
                    :characterId="character.id"/>
      <div v-else-if="isRequestQuestLoading" class="request-quest">
        <b-button variant="primary" disabled>
          <i class="fas fa-spinner fa-spin"/>
          {{ $t('quests.loading') }}
        </b-button>
      </div>
      <div v-else class="request-quest">
        <b-button variant="primary" @click="request(character.id)">
          {{ $t('quests.requestQuest') }}
        </b-button>
      </div>
    </div>
    <QuestSubmissionModal/>
    <b-modal v-model="showReputationModal" ok-only class="centered-modal" :title="$t('quests.reputation')">
      <div v-if="!isReputationInfoLoading" class="d-flex flex-column gap-3">
        <div class="d-flex justify-content-between">
          <span class="invisible">{{ $t('quests.rarityType.COMMON') }}</span>
          <div>{{ $t('quests.rarityType.COMMON') }}</div>
          <div>{{ $t('quests.rarityType.UNCOMMON') }}</div>
          <div>{{ $t('quests.rarityType.RARE') }}</div>
          <div>{{ $t('quests.rarityType.EPIC') }}</div>
          <div>{{ $t('quests.rarityType.LEGENDARY') }}</div>
        </div>
        <div v-for="(tierChance, index) in tierChances" class="d-flex justify-content-between align-items-center"
             :key="index">
          <span class="text-nowrap">{{ $t('quests.level', {level: index + 1}) }}</span>
          <div>
            <span>{{tierChance.common}}%</span>
          </div>
          <div>
            <span>{{tierChance.uncommon}}%</span>
          </div>
          <div>
            <span>{{tierChance.rare}}%</span>
          </div>
          <div>
            <span>{{tierChance.epic}}%</span>
          </div>
          <div>
            <span>{{tierChance.legendary}}%</span>
          </div>
        </div>
      </div>
      <span v-else>
        <i class="fas fa-spinner fa-spin"/>
        {{ $t('quests.loading') }}
      </span>
    </b-modal>
  </div>
  <div v-else-if="isLoading">
    <i class="fas fa-spinner fa-spin"/>
    {{ $t('quests.loading') }}
  </div>
  <div v-else class="m-4 font-weight-bold">
    {{ $t('quests.youNeedToHaveAtLeastOneCharacter') }}
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import {Nft} from '@/interfaces/Nft';
import {Accessors} from 'vue/types/options';
import QuestDetails from '@/components/smart/QuestDetails.vue';
import CharacterArt from '@/components/CharacterArt.vue';
import QuestSubmissionModal from '@/components/smart/QuestSubmissionModal.vue';
import Events from '@/events';

export interface Quest {
  progress: number;
  type?: RequirementType;
  reputation: number;
  id: number;
  tier?: Rarity;
  requirementType?: RequirementType;
  requirementRarity?: Rarity;
  requirementAmount: number;
  rewardType?: RewardType;
  rewardRarity?: Rarity;
  rewardAmount: number;
  reputationAmount: number;
}

export enum RequirementType {
  NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, RAID
}

export enum RewardType {
  NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD, EXPERIENCE
}

export enum Rarity {
  COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

export enum DustRarity {
  LESSER, GREATER, POWERFUL
}

export const VAR_REPUTATION_LEVEL_2 = 20;
export const VAR_REPUTATION_LEVEL_3 = 21;
export const VAR_REPUTATION_LEVEL_4 = 22;
export const VAR_REPUTATION_LEVEL_5 = 23;

export interface ReputationLevelRequirements {
  level2: number;
  level3: number;
  level4: number;
  level5: number;
}

export interface TierChances {
  common: number;
  uncommon: number;
  rare: number;
  epic: number;
  legendary: number;
}

interface StoreMappedActions {
  fetchCharacters(characterIds: (string | number)[]): Promise<void>;

  getCharacterQuestData(payload: { characterId: string | number }): Promise<Quest>;

  requestQuest(payload: { characterID: string | number }): Promise<void>;

  getReputationLevelRequirements(payload: { reputationLevels: number[] }): Promise<ReputationLevelRequirements>;

  getQuestTierChances(payload: { tier: number }): Promise<TierChances>;
}

interface StoreMappedGetters {
  charactersWithIds(ids: (string | number)[]): Nft[];
}

interface Data {
  characters: Nft[];
  reputationLevelRequirements?: ReputationLevelRequirements;
  isLoading: boolean;
  isRequestQuestLoading: boolean;
  isReputationInfoLoading: boolean;
  tierChances: TierChances[];
  showReputationModal: boolean;
}

export default Vue.extend({
  components: {QuestSubmissionModal, CharacterArt, QuestDetails},

  props: {
    showCosmetics: {
      type: Boolean,
      default: true
    },
  },

  data() {
    return {
      characters: [] as Nft[],
      reputationLevelRequirements: undefined,
      isLoading: false,
      isRequestQuestLoading: false,
      isReputationInfoLoading: false,
      tierChances: [] as TierChances[],
      showReputationModal: false,
    } as Data;
  },

  computed: {
    ...mapState(['ownedCharacterIds']),
    ...mapGetters(['charactersWithIds', 'getCharacterCosmetic']) as Accessors<StoreMappedGetters>,
  },

  methods: {
    ...mapActions([
      'fetchCharacters',
      'getCharacterQuestData',
      'requestQuest',
      'getReputationLevelRequirements',
      'getQuestTierChances',
    ]) as StoreMappedActions,

    getReputationLevel(reputation: number) {
      if (!this.reputationLevelRequirements) return;
      if (reputation < this.reputationLevelRequirements.level2) {
        return 1;
      } else if (reputation < this.reputationLevelRequirements.level3) {
        return 2;
      } else if (reputation < this.reputationLevelRequirements.level4) {
        return 3;
      } else if (reputation < this.reputationLevelRequirements.level5) {
        return 4;
      } else {
        return 5;
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

    async request(characterId: string | number) {
      try {
        this.isRequestQuestLoading = true;
        await this.requestQuest({characterID: characterId});
        await this.refreshQuestData();
      } finally {
        this.isRequestQuestLoading = false;
      }
    },

    async refreshQuestData() {
      const reputationLevels = [VAR_REPUTATION_LEVEL_2, VAR_REPUTATION_LEVEL_3, VAR_REPUTATION_LEVEL_4, VAR_REPUTATION_LEVEL_5];
      try {
        this.isLoading = true;
        this.reputationLevelRequirements = await this.getReputationLevelRequirements({reputationLevels});
        this.characters = await Promise.all(this.charactersWithIds(this.ownedCharacterIds).filter(Boolean).map(async (character) => {
          character.quest = await this.getCharacterQuestData({characterId: character.id});
          console.log(character);
          return character;
        }));
      } finally {
        this.isLoading = false;
      }
    },

    async showReputationInfoModal() {
      try{
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
    }
  },

  async mounted() {
    await this.refreshQuestData();
    Events.$on('refresh-quest-data', async () => {
      console.log('event!');
      await this.refreshQuestData();
    });
  },

  watch: {
    async ownedCharacterIds(characterIds) {
      await this.fetchCharacters(characterIds);
      await this.refreshQuestData();
    }
  },
});
</script>

<style scoped lang="scss">
@import '../styles/character-cosmetics.css';

.character {
  position: relative;
  width: 14em;
  height: 25em;
  background-position: center;
  background-repeat: no-repeat;
  background-size: 115%;
  background-color: #2e2e30cc;
  background-image: url('../assets/cardCharacterFrame.png');
  border: 1px solid #a28d54;
  border-radius: 15px;
  padding: 0.5rem;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  overflow: hidden;
}

.character .art {
  width: 100%;
  min-height: 0;
  height: 18rem;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
}

.character img {
  object-fit: contain;
}

.above-wrapper {
  position: absolute;
  top: 270px;
  left: 0;
  right: 0;
  z-index: 100;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
}

.reputation-progress {
  width: 75%;
}

.xp {
  position: absolute;
  bottom: 30px;
  width: 100%;
  display: flex;
  right: 0;
  flex-direction: column;
  align-items: center;
}

.xp-text {
  position: absolute;
  bottom: -12%;
}

.quest-row,
.quests-container {
  gap: 1rem;
}

.request-quest {
  display: flex;
  justify-content: center;
  align-items: center;
  border: 1px solid;
  border-radius: 5px;
  width: 25rem;
  height: auto;
}

.white-space {
  white-space: break-spaces;
}

@media (max-width: 576px) {
}
</style>
