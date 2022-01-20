<template>
  <div class="d-flex flex-column quests-container">
    <div v-for="character in characters" :key="character.id" class="row quest-row">
      <div v-if="character.quest" class="character"
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
        <div class="xp">
          <span>Reputation lvl {{ 0 }}</span>
          <strong class="outline xp-text">{{ character.quest.reputation || 0 }} / {{ 9999 }}</strong>
          <b-progress class="reputation-progress" :max="9999" :value="character.quest.reputation"
                      variant="primary"/>
        </div>
      </div>
      <QuestDetails v-if="character.quest && character.quest.id !== 0" :quest="character.quest"
                    :characterId="character.id"/>
      <div v-else class="request-quest">
        <b-button variant="primary w-100" @click="request(character.id)">
          {{ $t('quests.request') }}
        </b-button>
      </div>
    </div>
    <QuestSubmissionModal/>
    <QuestsDashboard/> <!-- TODO: Quests Dashboard is temporarily here, find a place for it elsewhere -->
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import foundersShield from '../assets/shield1.png';
import {Nft} from '@/interfaces/Nft';
import {Accessors} from 'vue/types/options';
import QuestDetails from '@/components/smart/QuestDetails.vue';
import CharacterArt from '@/components/CharacterArt.vue';
import QuestSubmissionModal from '@/components/smart/QuestSubmissionModal.vue';
import QuestsDashboard from '@/components/smart/QuestsDashboard.vue';

export interface Quest {
  progress?: number;
  type?: RequirementType;
  reputation?: number;
  id?: number;
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
  NONE, WEAPON, JUNK, DUST, TRINKET, SHIELD
}

export enum Rarity {
  COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

interface StoreMappedActions {
  getCharacterQuestData(payload: { characterId: string | number }): Promise<Quest>;

  requestQuest(payload: { characterID: string | number }): Promise<void>;
}

interface StoreMappedGetters {
  charactersWithIds(ids: (string | number)[]): Nft[];
}

export default Vue.extend({
  components: {QuestSubmissionModal, CharacterArt, QuestDetails, QuestsDashboard},

  props: {
    showCosmetics: {
      type: Boolean,
      default: true
    },
  },

  data() {
    return {
      characters: [] as Nft[],
    };
  },

  computed: {
    ...mapState(['ownedCharacterIds']),
    ...mapGetters(['charactersWithIds', 'getCharacterCosmetic']) as Accessors<StoreMappedGetters>,

    getFoundersShield() {
      return foundersShield;
    }
  },

  methods: {
    ...mapActions(['getCharacterQuestData', 'requestQuest']) as StoreMappedActions,

    async request(characterId: string | number) {
      await this.requestQuest({characterID: characterId});
      await this.refreshQuestData();
    },

    async refreshQuestData() {
      for (const character of this.characters) {
        character.quest = await this.getCharacterQuestData({characterId: character.id});
        console.log(character.quest);
      }
    },

    displayCharacters(): Nft[] {
      return this.charactersWithIds(this.ownedCharacterIds).filter(Boolean);
    }
  },

  async mounted() {
    this.characters = this.displayCharacters();
    await this.refreshQuestData();
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
  align-items: stretch;
  width: 25rem;
  padding: 5rem;
}

@media (max-width: 576px) {
}
</style>
