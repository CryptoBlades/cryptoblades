<template>
  <div class="d-flex flex-column quests-container">
    <div v-for="character in characters" :key="character.id" class="row quest-row">
      <div v-if="character.questData" class="character"
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
          <strong class="outline xp-text">{{ character.questData.reputation || 0 }} / {{ 9999 }}</strong>
          <b-progress class="reputation-progress" :max="9999" :value="character.questData.reputation"
                      variant="primary"/>
        </div>
      </div>
      <QuestDetails v-if="character.questData && character.questData.id !== 0" :questData="character.questData" :characterId="character.id"/>
      <div v-else class="request-quest">
        <b-button variant="primary w-100" @click="request(character.id)">
          {{ $t('quests.request') }}
        </b-button>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import foundersShield from '../assets/shield1.png';
import {Nft} from '@/interfaces/Nft';
import {Accessors} from 'vue/types/options';
import QuestDetails, {RequirementType} from '@/components/smart/QuestDetails.vue';
import CharacterArt from '@/components/CharacterArt.vue';

export interface QuestData {
  id: number;
  progress: number;
  type: RequirementType;
  reputation: number;
}

interface StoreMappedActions {
  getCharacterQuestData(payload: { characterId: string | number }): Promise<{ 0: string, 1: string, 2: string, 3: string, 4: string }>;
  requestQuest(payload: { characterID: string | number }): Promise<void>;
}

interface StoreMappedGetters {
  charactersWithIds(ids: (string | number)[]): Nft[];
}

export default Vue.extend({
  components: {CharacterArt, QuestDetails},

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
    },
  },

  methods: {
    ...mapActions(['getCharacterQuestData', 'requestQuest']) as StoreMappedActions,

    async request(characterId: string | number) {
      await this.requestQuest({characterID: characterId});
      await this.refreshQuestData();
    },

    async refreshQuestData() {
      for (const character of this.characters) {
        const questDataRaw = await this.getCharacterQuestData({characterId: character.id});
        console.log(questDataRaw);
        character.questData = {
          id: +questDataRaw[0],
          progress: +questDataRaw[1],
          type: +questDataRaw[2] as RequirementType,
          reputation: +questDataRaw[3],
        } as QuestData;
      }
    }
  },

  async mounted() {
    this.characters = this.charactersWithIds(this.ownedCharacterIds).filter(Boolean);
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
  padding: 3rem;
}

@media (max-width: 576px) {
}
</style>
